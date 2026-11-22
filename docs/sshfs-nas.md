# SSHFS NAS（ユーザー権限・参照時接続）

`home/4osme/default.nix` が `modules/home-manager/sshfs-nas.nix` を読み込む。
systemd の `.automount` はユーザーマネージャーでは使えないため、
ユーザーサービス `sshfs-nas` 内の afuse で代替する。

- ログイン時には afuse が `~/mnt` に待ち受け用 FUSE をマウントするだけで、
  NAS には接続しない。`~/mnt` はこのサービス専用（既存ファイルを置かない）。
- `~/mnt/server/` を開くと `sshfs@172.16.50.2:/mnt` に SSHFS 接続する。
  `~/mnt` の一覧表示だけでは接続しないが、ファイルマネージャーによる
  サブディレクトリの検査や検索・インデックス作成もアクセスになり得る。
- 初回接続失敗時は 5 秒間隔で最大 3 回試行する。SSH 接続タイムアウトは
  1 回 5 秒。全試行に失敗するとアクセス元にエラーを返し、次のアクセスで
  再試行する（待ち受けサービスは終了しない）。
- 接続後の切断は `reconnect` と SSH keepalive で検出・再接続する。
  NAS 停止中は I/O が待たされる場合があり、切断前のファイルハンドルを
  使う操作が失敗した場合はファイルを開き直す。
- アイドル時の自動アンマウントは設定しない。ログアウト等でユーザー
  マネージャーが停止すると解除する。linger を有効にしていれば継続する。
- afuse は実際の SSHFS マウントを `$XDG_RUNTIME_DIR/sshfs-nas/` 配下に作り、
  `~/mnt/server` へのアクセスを中継する。直接 SSHFS をマウントする場合より
  オーバーヘッドがある。

## SSH の準備

Nix で配布するのは `~/.ssh/config` とユーザー systemd ユニット
（および実行用スクリプト）のみ。Home Manager が NixOS ホストの利用ユーザー
（`4osme`）の `~/.ssh/config` を以下の内容で管理する。
既存の未管理 `~/.ssh/config` がある場合は、適用前にバックアップし、
必要な設定を Nix 側へ統合すること（自動で上書き・削除はしない）。

```sshconfig
Host sshfs
    HostName 172.16.50.2
    User sshfs
    IdentityFile ~/.ssh/sshfs
    IdentitiesOnly yes
```

`BatchMode=yes`、`StrictHostKeyChecking=yes` なので、パスワード入力や
未知のホスト鍵の確認待ちはしない。事前に別経路でホスト鍵の指紋を確認し、
`known_hosts` に登録すること。暗号化された秘密鍵を使う場合は、
ユーザーサービスから利用できる ssh-agent と鍵のロードが必要。

### 鍵は Nix 管理しない

- 秘密鍵は手動で `~/.ssh/sshfs` に配置する。設定に含めるのはパス文字列
  だけで、秘密鍵本体はリポジトリや Nix store に入れない。
- 公開鍵は鍵生成時に NAS 側のユーザー `sshfs` の `authorized_keys` に
  手動で転送する。Nix での公開鍵配布・登録は行わない。
- `known_hosts` も手動で管理する。VLAN 内でもホスト鍵の検証は省略しない。
- `~/.ssh` は所有ユーザーのみアクセス可能（0700）、秘密鍵は所有ユーザー
  のみ読み書き可能（0600）にしておく。

## 適用後の確認

以下は **Distrobox 内ではなく NixOS ホスト上の利用ユーザー**で実行する。
新規ファイルは flake の Git ソースに含める必要があるため、適用前に
`modules/home-manager/sshfs-nas.nix` を Git に追加すること。
NixOS / Home Manager の通常の適用後、新しいユーザーサービスが有効になる。
必要なら手動で開始する。

```sh
systemctl --user start sshfs-nas.service
ls ~/mnt
ls ~/mnt/server/
journalctl --user -u sshfs-nas.service -b
```

NAS を停止した状態で `~/mnt/server/` にアクセスし、再試行とエラー返却を確認する。
NAS 復旧後、もう一度アクセスして接続できることを確認する。
従来の root 側 `.automount` / `.mount` はこの設定では変更しないため、
移行確認後に旧環境で無効化する。

既存の root マウントから `_netdev`、`allow_other`、固定 `uid/gid`、
鍵・known_hosts の絶対パス指定は引き継がない。`idmap=user` は維持する。
キャッシュは `auto_cache` とディレクトリキャッシュを使い、
外部からの更新を見落としやすい `kernel_cache` は指定しない。
FUSE のマウント補助には NixOS 標準の `/run/wrappers/bin` を使うため、
`NoNewPrivileges` やプライベートな mount namespace は設定しない。
