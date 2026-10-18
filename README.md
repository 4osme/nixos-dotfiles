# dotfiles — HyprTomic NixOS

`j7b3y/fedora-hyprtomic/` のシステム (Fedora Atomic ホスト + Arch distrobox GUI) を
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
| `sigma-file-manager` 2.2.0 | 公式debを再パッケージ (`pkgs/sigma-file-manager`) | GPL-3.0-or-later。Tauri製バイナリを autoPatchelf。デフォルトFM (nemo置換) |
| `sunshine` (JIS) | ../sunshine-nix から vendored (`pkgs/sunshine/`) | GPL-3.0-or-later + MIT (詳細と出典は `pkgs/sunshine/README.md`)。`main-desktop` でユーザーサービスとして起動 |
| quickshell パッチ | fedora-hyprtomic `files/gui-build/patches/` | upstream 修正が入ったら自動スキップ |

## 今後の作業

- `dell-laptop` 環境モジュール (tpm2+LUKS, tailsale, edid, waybar バッテリー等)
- mozkey の Bazel ビルドが現実的になれば prebuilt から切替
- sigma-file-manager のソースビルド (cargo-tauri.hook) への切替検討
