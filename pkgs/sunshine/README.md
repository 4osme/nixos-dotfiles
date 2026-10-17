# Sunshine JIS patches (vendored from ../sunshine-nix)

This directory is a verbatim copy of the sunshine-nix tree's patch set. The
same overrideAttrs logic lives in `overlays/default.nix` (it patches nixpkgs'
`sunshine`), the package is included on main-desktop
(`modules/environments/main-desktop/sunshine.nix`) and `home/sunshine.nix`
runs it as a user service.

---

# Sunshine JIS keyboard support for NixOS (option B: nixpkgs override)

NixOS で JIS キーボード対応の Sunshine をビルドするための最小セットです。
**Sunshine / libvirtualhid のフォークは不要**で、nixpkgs の `sunshine` を
override してパッチを当てるだけです（公開要素はこのディレクトリのみ）。

## 前提（upstream の状況）

LizardByte 側の JIS 対応 PR は **まだ未マージ**です（2026-10 時点）:

- `LizardByte/Sunshine#5542` "fix(keyboard): Japanese mapping" — open
- `LizardByte/libvirtualhid#101` "fix(keyboard): Japanese mapping" — open
  （`mergeable_state: dirty` でコンフリクトあり）

そのため upstream のリリースには JIS 対応が入っていません。マージされたら
このパッチ群は不要になります。

## 内容

```
default.nix
patches/
  0001-sunshine-non-normalized-key-flag.patch     # uinput 経路にも non-normalized フラグを通す
  0002-sunshine-wayland-retry.patch               # Wayland レイアウト検証のリトライ（JIS 以外の推奨修正）
  0003-libvirtualhid-jis-keyboard-mapping.patch   # JIS マッピング本体（uhid バックエンド）
```

### 検証済みの適用先

`patch --dry-run` および実適用で確認済み:

- Sunshine `v2026.914.233613`（nixpkgs が現在パッケージしている版と同じ）
- `third-party/libvirtualhid` = `53e1a949fc0784af716b782ddfa6c647cafd1f05`
  （上記タグが pin している submodule リビジョン）

0003 は upstream の libvirtualhid **master 先頭（2026-10-16 時点）とは
コンテキストが異なります**（関数の位置と配列要素数が変わっているため）。
nixpkgs が Sunshine を更新したら、その submodule pin に合わせて 0003 を
リベースしてください（0001/0002 は数行なので簡単です）。

## 使い方

flake なし:

```sh
nix-build ./default.nix
```

システム設定・overlay から:

```nix
# flake.nix などで
sunshine-jis = import /path/to/sunshine-nix { pkgs = pkgs; };
# → environment.systemPackages = [ sunshine-jis ];
```

`ENABLE_BROKEN_AV1_ENCODER`（SVT-AV1 ソフトウェア AV1）は**触っていません**。
jis ビルドでは有効でしたが、NixOS では nixpkgs の既定のままにします
（有効にすると `av1_mode = 2` で CPU エンコードに落ちる挙動も再現します）。

## ライセンス

- `0001` / `0002`（Sunshine 側のコード）: **GPL-3.0-or-later**
  （LizardByte/Sunshine と同じ）。公開 dotfiles に置く場合はこの表記を保持してください。
- `0003`（libvirtualhid 側のコード）: **MIT**。
  変更対象の `src/platform/linux/uhid_backend.cpp` は libvirtualhid の
  "non-driver backends" に属し MIT です（同リポジトリの `LICENSE.md` /
  `LICENSES/MIT.md` 参照）。Windows ドライバ／macOS ブローカー部分は
  LizardByte のプロプライエタリなので、**フォークして配布する場合は
  upstream のライセンス表記をそのまま残し、MIT 部分だけを MIT として
  扱ってください**（このパッチは MIT 部分のみを変更します）。
- ビルド済みバイナリを第三者に配布する場合（Nix binary cache 等）は
  GPL-3.0 のソース提供義務があるため、このディレクトリ（パッチ＋レシピ）
  を公開できる場所に置いてください。

## クライアント側との関係

JIS はクライアントとホストの両方が揃って成立します:

- クライアント（moonlight-web-stream 側）は JIS キーを
  `SS_KBE_FLAG_NON_NORMALIZED` 付きで送る必要があります
- ホスト側（このパッチ）がそのフラグを見て `KEY_YEN` / `KEY_RO` /
  `KEY_KATAKANAHIRAGANA` / `KEY_HENKAN` / `KEY_MUHENKAN` に変換します

クライアントは別環境で保守しているため、このディレクトリには含めません。
