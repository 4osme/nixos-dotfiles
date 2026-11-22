# main-desktop の LAN / NAS VLAN

`hosts/main-desktop/networking.nix` のみで有効化する。他ホストには適用しない。

- タグなし LAN：既存の NetworkManager の DHCP 接続を維持する。
  新規インストール時も通常の Ethernet 自動接続（DHCP）を使用する。
- NAS：物理 Ethernet 上に VLAN ID **202**、インターフェース **`nas202`** を作り、
  IPv4 **`172.16.50.3/24`** を設定する。Gateway・DNS は追加しない。
  デフォルトルートへの採用は禁止し、この VLAN の IPv6 は無効にする。
- スイッチ側の接続ポートも、通常 LAN を untagged、VLAN 202 を tagged として
  通す必要がある。

## 親ポートの選択

MAC・PCI 接続位置・`enp6s0` 等の名前には固定しない。
起動時に `/sys/class/net` から、デバイス実体を持つ Ethernet を列挙する。
Wi-Fi、ループバック、veth、bridge、既存 VLAN は候補に含めない。

候補が **1ポートだけ**の場合に限り、NetworkManager の実行時プロファイル
`/run/NetworkManager/system-connections/main-desktop-vlan202.nmconnection`
を作成して有効化する。このプロファイルは再起動時に親ポートを再検出する。

0ポート・複数ポートなら VLAN は作成せず、ログに記録して30秒後に再試行する。
候補に含まれる USB Ethernet や追加 NIC を接続したまま起動すると、
複数ポートとして扱われる。

選択はサービス起動時に行い、成功後の NIC 追加・交換は自動追従しない。
交換や構成変更は原則再起動して反映すること。複数ポート構成へ変更する場合は、
自動選択をやめて明示的な親ポート指定へ変更する。

## 確認

新規 `.nix` と `vlan202.sh` は適用前に Git に追加して flake に含める。
通常の NixOS 適用後、以下を **main-desktop のホスト側（Distrobox 外）**で確認する。

```sh
systemctl status main-desktop-vlan202.service
journalctl -u main-desktop-vlan202.service -b
ip -d link show nas202
ip -4 address show dev nas202
ip -4 route show dev nas202
ip -4 route get 172.16.50.2
```

`nas202` の VLAN ID が202で、`172.16.50.0/24` の直結ルートのみ追加され、
既存 LAN のデフォルトルートが維持されていることを確認する。
この実装の追加だけでは、現在実行中の環境のネットワーク設定は変更しない。
