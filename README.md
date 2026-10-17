# dotfiles — HyprTomic NixOS

`../fedora-hyprtomic/` のシステム (Fedora Atomic ホスト + Arch distrobox GUI) を
**NixOS + Home Manager** へ移植した dotfiles です。要件と移行内容の仕様は
[AGENTS.md](./AGENTS.md) を参照してください。

## 構成

| パス | 役割 |
|---|---|
| `flake.nix` | 入力 (nixpkgs 26.05 / home-manager / nix-cachyos-kernel) と `nixosConfigurations` |
| `hosts/main-desktop/` | main-desktop 環境 (このマシン)。`storage.nix` (要手動定義) / `hardware-configuration.nix` (インストール時に生成) |
| `modules/system/` | OS 基本層: boot (systemd-boot + XBOOTLDR), kernel, nix, networking/BT, locale/IME, audio, users, sddm, fonts, portals, flatpak, distrobox, KVM, security, hardware |
| `modules/desktop/` | Hyprland セッション (programs.hyprland + uwsm) |
| `modules/environments/main-desktop/` | Intel GPU (i915 出禁/xe), NPU, VFIO (Arc B580), Vypr, CS9711F ドライバ |
| `home/` | Home Manager: ツール類, zsh, ユーザーサービス, dotfiles sync ツール |
| `overlays/` + `pkgs/` | 独自ビルド: hyprbind, hypremoji, Vypr, mozkey, SDDM theme, Google Sans Flex, libfprint-cs9711, quickshell パッチ |
| `files/home/` | `$HOME` へ配る dotfiles (fedora-hyprtomic の `/etc/skel` 相当) |
| `files/home-<host>/` | ホスト別 dotfiles オーバーレイ (例: main-desktop の緩和した hypridle) |
| `files/system/` | PAM ゲート, Vypr ヘルパー, quickshell パッチなどの素材 |
| `.github/workflows/` | CI: ビルド + Cachix、`nix flake update` → PR → 自動マージ |

## 手動での定義が必要な項目

1. **ストレージ** — `hosts/main-desktop/storage.nix` の UUID プレースホルダを埋める。
   ディスクレイアウトは現行 Fedora ホストの構成をそのまま参照:
   - `nvme1n1p1` 600M vfat → `/efi` (ESP)
   - `nvme1n1p2` 2G xfs → `/boot` (XBOOTLDR; systemd-boot のカーネル置き場)
   - `nvme1n1p3` 1.9T btrfs → `/` (@)・`/home` (@home)
   - `nvme2n1p1` 112G swap → swap (ハイバネート/レジューム先)
   - `nvme0n1` 954G xfs (label `develop`) → `/mnt/develop`

   インストール時のパーティション例は `storage.nix` のコメントを参照。
2. **hardware-configuration.nix** — インストール先で `nixos-generate-config` を実行し、
   `hosts/main-desktop/hardware-configuration.nix` を置き換える
   (fileSystems/swapDevices ブロックは `storage.nix` 側にあるため取り込まない)。
3. **Cachix** — リポジトリの Settings → Secrets に `CACHIX_CACHE_NAME` と
   `CACHIX_AUTH_TOKEN` を追加。作成したキャッシュの substituter URL と公開鍵を
   `modules/system/nix.nix` の TODO の位置へ追記する (未設定でもビルドは動く)。
4. **自動マージ** — Settings → General で `Allow auto-merge` を有効化し、
   branch protection で `build` ワークフローを required にする。
5. 初期パスワード — `underdone` / `nixos`。初回ログイン後すぐ `passwd underdone` で変更。

## インストールの流れ (main-desktop)

```bash
# 1. インストーラー (NixOS ISO) で起動し、storage.nix のコメントどおりに
#    パーティションを作成 (Fedora のレイアウトを踏襲)。

# 2. マウントして生成 (fileSystems は storage.nix を使うため後で差し替え)
nixos-generate-config --root /mnt

# 3. このリポジトリを /mnt へ持って行き、hardware-configuration.nix を配置
#    (生成されたファイルの fileSystems/swapDevices は削除)

# 4. インストール
nixos-install --flake /mnt/var/lib/dotfiles#main-desktop

# 5. 初回起動後 (Home Manager の dotfiles を $HOME へ反映するため一度 switch)
sudo nixos-rebuild switch --flake ~/repository/dotfiles#main-desktop
passwd underdone
fprintd-enroll                 # 指紋 (CS9711F) の登録
```

以後の更新は `sudo nixos-rebuild switch --flake .#main-desktop` のみ
(dotfiles・テーマ・モニタ設定は Home Manager が同時に反映)。

## dotfiles の配布方法 (Home Manager)

`files/home` (+ ホスト別オーバーレイ `files/home-<host>`) の全ファイルを
**Home Manager (`xdg.configFile` / `home.file`) で $HOME に展開**します
(fedora-hyprtomic の skel 同期 `hyprtomic-config-sync` は廃止)。

- 内容は Nix store からの読み取り専用リンク。`nixos-rebuild switch` /
  `home-manager switch` のたびに一致します(旧ファイルは `.hm-backup` へ退避)。
- 実行時に書き換えられる dotfile を無くすため、**テーマ切替 (`apply-theme.sh`)
  は廃止**。テーマは md3-amethyst 固定で、Theme.qml のパラメータテーブルが
  唯一の定義(対応する gtk.css / qt colors / Kvantum / rofi colors /
  ghostty theme.conf / kdeglobals / hypr/theme.lua は files/home に同梱の静的値)。
- モニタ/ワークスペース (`monitors.lua` / `workspaces.lua`)・ホスト固有の
  Lua (`host.lua`: quadgrid・Cider/X の配置・Sunshine プロファイル)は
  `files/home-main-desktop/` 側で HM 管理。
- デバッグ用の `~/.config/hypr/local.conf` だけは**管理外**のまま残しています
  (`hyprland.lua` が最後に読み込むため、既定を一時的に上書きして検証できます)。
- fcitx5 (`profile` / `classicui.conf`) と gsettings 相当 (dconf) も HM 管理。
- 旧 skel 同期時代の残骸 (`~/.local/state/hyprtomic/`, `~/.config/quickshell/ii/current-theme`)
  は移行後に手で削除して構いません (もう参照されません)。
- アイコン解決 `resolve-icons` ラッパー (`pkgs/resolve-icons`) が pygobject 依存を供給します。

## fedora-hyprtomic からの主な変更点

- **GUI コンテナ (hyprtomic-gui) 廃止**: quickshell シェル、IME (fcitx5 +
  mozkey IbG)、clipse/cliphist、hyprbind、hypremoji などは NixOS ネイティブで
  実行。`hyprtomic-gui-shell` / `hyprtomic-distrobox-apps` は不要になり、
  ランチャーは Host (ネイティブ) と Flatpak の 2 ソースに整理 (`Launcher.qml`
  の `guiContainer` フォールバックを Host に変更)。
- **dotfiles は Home Manager 管理 / テーマ固定**: `files/home` を
  `xdg.configFile`/`home.file` でリンク (`hyprtomic-config-sync` 廃止)。
  `apply-theme.sh` とテーマ切替 UI も廃止し、**md3-amethyst 固定**
  (Theme.qml のパラメータテーブル = Alchemist が唯一の定義)。
  モニタ/ワークスペースと host.lua (quadgrid・Cider/X 配置・Sunshine) は
  main-desktop オーバーレイで HM 管理、`local.conf` はデバッグ導線として残存。
  fcitx5・dconf も HM 管理。
- **Flatpak**: `org.mozilla.firefox` と `org.gnome.Loupe` のみ事前導入
  (Fedora と同じ)。Bitwarden / Mission Center / Vesktop / Chrome /
  EasyEffects は Nix パッケージ (AGENTS.md の検討事項の暫定判断)。
- **ポータル**: `hyprland;gtk`、Background のみ gnome。Fedora の skel は
  FileChooser を kde にしていたが kde ポータルは入れていない (必要なら
  `modules/system/portals.nix` を変更)。
- **Vypr**: バイナリは `pkgs/vypr` (v0.5.0 に固定 + `files/scripts/vypr-build.sh`
  と同じ 4 パッチを `patches/apply.py` で適用)。IOMMU kargs / qemu.conf
  (user=underdone) / libvirtd グループ / ソケットは宣言的に設定済み。
  `hyprtomic-vypr-setup` / `hyprtomic-vypr-create-vm` は Fedora 版のポータブルな
  手順 (ドメイン XML 編集・ペアリング CD・GPU アタッチ・ゲスト電源設定) を移植。
- **カーネル**: `linux-cachyos-bore-lto-x86_64-v3` (xddxdd/nix-cachyos-kernel,
  release ブランチ + pinned overlay + lantian キャッシュ)。
- **hypridle**: main-desktop では緩和 (600s lock / 1200s dpms / 3600s
  suspend-then-hibernate)。`boot.resumeDevice` = 112G swap。
- **dex**: Fedora の `dex-autostart` は NixOS の `dex` に置換
  (`hyprland.lua` の autostart を更新済み)。
- **fingerprint**: SDDM / hyprlock の PAM ゲート (空 Enter で指紋) はそのまま移植。
  main-desktop は CS9711 対応のため `pkgs.libfprint-cs9711` で `libfprint` を
  差し替え (COPR `cwt/libfprint-cs9711` 相当)。
- **Sunshine (JIS)**: ../sunshine-nix のJISキーボード対応パッチを統合し、
  main-desktop でユーザーサービスとして自動起動 (`home/sunshine.nix`)。
  ディスプレイプロファイル連携 (`host.lua` + `hypr-stream-display.py`) は
  従来どおり。

## 独自パッケージの出典

| パッケージ | 出典 | 備考 |
|---|---|---|
| `hyprbind` 0.1.4 | ry2x/HyprBind | MIT/OFL。ソースからビルド |
| `hypremoji` 1.3.0 | Musagy/hypremoji | AUR `hypremoji` と同一 upstream。upstream に Cargo.lock が無いため生成済み lock を `pkgs/hypremoji/` に固定 |
| `fcitx5-mozkey-ibg` 0.10.4 | kazormia296/mozkey-ibg の Arch prebuilt | AUR `mozkey-ibg-bin` と同一成果物。fcitx5 のみ autoPatchelf (付属 llama-server/mozc_server はほぼ静的) |
| `vypr` 0.5.0 | Amzi-01/Vypr | Unlicense。4 パッチ + `vypr-setup.exe` 同梱 |
| `sddm-hyprtomic-theme` | Keyitdev/sddm-astronaut-theme + `files/sddm-theme` | GPL-3.0 |
| `google-sans-flex` | ririko66z/dots-hyprland COPR RPM | OFL。Fedora の gui-04-fonts.sh と同じ成果物 |
| `libfprint-cs9711` 1.94.10 | archeYR/libfprint-CS9711 | LGPL-2.1+。1500ms リトライパッチ付き |
| `sunshine` (JIS) | ../sunshine-nix から vendored (`pkgs/sunshine/`) | GPL-3.0-or-later + MIT (詳細と出典は `pkgs/sunshine/README.md`)。`main-desktop` でユーザーサービスとして起動 |
| quickshell パッチ | fedora-hyprtomic `files/gui-build/patches/` | upstream 修正が入ったら自動スキップ |

## CI / バイナリキャッシュ

- `build.yml`: 全 `nixosConfigurations` を評価→ビルドし、Cachix 設定時は
  ビルド成果を push (secrets 未設定ならスキップ)。独自パッケージもビルド。
- `update.yml`: 週次で `nix flake update` → `flake-update` ブランチへ push →
  PR 作成 → auto-merge (required checks 通過後)。
- 実機は `nix.settings.substituters` (modules/system/nix.nix) でキャッシュを
  引く。lantian (cachyos kernel) は設定済み。

## 今後の作業

- `dell-laptop` 環境モジュール (tpm2+LUKS, tailsale, edid, waybar バッテリー等)
- FileManager の sigma-file-manager 移行 (検討中)
- Flatpak 併用の最終判断 (vesktop / Mission Center / Bitwarden / Chrome / EasyEffects)
- mozkey の Bazel ビルドが現実的になれば prebuilt から切替
