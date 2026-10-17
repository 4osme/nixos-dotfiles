// Platform menus (system tray right-click) only work in QApplication mode:
// quickshell's StatusNotifierItem.display() requires it.
//@ pragma UseQApplication

import Quickshell
import QtQuick
import Quickshell.Io

import "modules/powermenu" as PowerMenu
import "modules/controlcenter" as ControlCenter
import "modules/notifications" as Notifications
import "modules/launcher" as Launcher
import "modules/osd" as Osd
import "modules/shelf" as Shelf

ShellRoot {
    id: root

    // The theme is fixed (md3-amethyst, see Theme.qml); Home Manager owns the
    // theme files (gtk.css, qt colors, Kvantum, rofi, ghostty, hypr/theme.lua).
    // There is no current-theme file and no apply-theme.sh anymore.

    // --- Module Instances ---
    // Each component manages its own visibility and IPC handler internally.
    // Nothing auto-opens on startup.

    Shelf.Shelf {
        id: shelf
    }

    PowerMenu.PowerMenu {
        id: powerMenu
    }

    ControlCenter.ControlCenter {
        id: controlCenter
    }

    Notifications.NotificationCenter {
        id: notificationCenter
    }

    Notifications.NotificationToastLayer {
        id: notificationToasts
    }

    Launcher.Launcher {
        id: appLauncher
    }

    Osd.VolumeOsd {
        id: volumeOsd
    }

    // --- Mutual Exclusivity ---

    Connections {
        target: powerMenu
        function onMenuOpenChanged() {
            if (powerMenu.menuOpen) {
                controlCenter.panelVisible = false;
                notificationCenter.panelVisible = false;
                appLauncher.panelVisible = false;
            }
        }
    }

    Connections {
        target: controlCenter
        function onPanelVisibleChanged() {
            if (controlCenter.panelVisible) {
                powerMenu.menuOpen = false;
                notificationCenter.panelVisible = false;
                appLauncher.panelVisible = false;
            }
        }
    }

    Connections {
        target: notificationCenter
        function onPanelVisibleChanged() {
            if (notificationCenter.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                appLauncher.panelVisible = false;
            }
        }
    }

    Connections {
        target: appLauncher
        function onPanelVisibleChanged() {
            if (appLauncher.panelVisible) {
                powerMenu.menuOpen = false;
                controlCenter.panelVisible = false;
                notificationCenter.panelVisible = false;
            }
        }
    }
}
