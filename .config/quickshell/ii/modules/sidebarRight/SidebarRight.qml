import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "./quickToggles/"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    property int sidebarPadding: 12
    property string settingsQmlPath: Quickshell.shellPath("settings.qml")
    property bool showDeviceSelector: false
    property bool deviceSelectorInput: false
    property int dialogMargins: 16
    property var selectedDevice: null

    function showDeviceSelectorDialog(input: bool) {
        // If already open with same type, close it
        if (root.showDeviceSelector && root.deviceSelectorInput === input) {
            root.showDeviceSelector = false
            root.selectedDevice = null
            return
        }

        root.selectedDevice = null
        root.showDeviceSelector = true
        root.deviceSelectorInput = input
     }

    Keys.onPressed: (event) => {
        // Close dialog on pressing Esc if open
    }

    PanelWindow {
        id: sidebarRoot
        visible: GlobalStates.sidebarRightOpen

        function hide() {
            GlobalStates.sidebarRightOpen = false
        }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:sidebarRight"
        // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
        // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
        }

        HyprlandFocusGrab {
            id: grab
            windows: [ sidebarRoot ]
            active: GlobalStates.sidebarRightOpen
            onCleared: () => {
                if (!active) sidebarRoot.hide()
            }
        }

        Loader {
            id: sidebarContentLoader
            active: GlobalStates.sidebarRightOpen
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                left: parent.left
                topMargin: Appearance.sizes.hyprlandGapsOut
                rightMargin: Appearance.sizes.hyprlandGapsOut
                bottomMargin: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }
            width: sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

            focus: GlobalStates.sidebarRightOpen
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    if (root.showDeviceSelector) {
                        root.showDeviceSelector = false
                        event.accepted = true;
                    } else {
                        sidebarRoot.hide();
                    }
                }
            }

            sourceComponent: Item {
                implicitHeight: sidebarRightBackground.implicitHeight
                implicitWidth: sidebarRightBackground.implicitWidth

                StyledRectangularShadow {
                    target: sidebarRightBackground
                }
                Rectangle {
                    id: sidebarRightBackground

                    anchors.fill: parent
                    implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
                    implicitWidth: sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: sidebarPadding
                        spacing: sidebarPadding

                        RowLayout {
                            Layout.fillHeight: false
                            spacing: 10
                            Layout.margins: 10
                            Layout.topMargin: 5
                            Layout.bottomMargin: 0

                            CustomIcon {
                                id: distroIcon
                                width: 25
                                height: 25
                                source: SystemInfo.distroIcon
                                colorize: true
                                color: Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer0
                                text: Translation.tr("Up %1").arg(DateTime.uptime)
                                textFormat: Text.MarkdownText
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            ButtonGroup {
                                QuickToggleButton {
                                    toggled: false
                                    buttonIcon: "restart_alt"
                                    onClicked: {
                                        Hyprland.dispatch("reload")
                                        Quickshell.reload(true)
                                    }
                                    StyledToolTip {
                                        content: Translation.tr("Reload Hyprland & Quickshell")
                                    }
                                }
                                QuickToggleButton {
                                    toggled: false
                                    buttonIcon: "settings"
                                    onClicked: {
                                        GlobalStates.sidebarRightOpen = false
                                        Quickshell.execDetached(["qs", "-p", root.settingsQmlPath])
                                    }
                                    StyledToolTip {
                                        content: Translation.tr("Settings")
                                    }
                                }
                                QuickToggleButton {
                                    toggled: false
                                    buttonIcon: "power_settings_new"
                                    onClicked: {
                                        GlobalStates.sessionOpen = true
                                    }
                                    StyledToolTip {
                                        content: Translation.tr("Session")
                                    }
                                }
                            }
                        }

                        ButtonGroup {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 5
                            padding: 5
                            color: Appearance.colors.colLayer1

                            NetworkToggle {}
                            BluetoothToggle {}
                            NightLight {}
                            GameMode {}
                            IdleInhibitor {}
                            EasyEffectsToggle {}
                            CloudflareWarp {}
                        }

                        // Center widget group
                        CenterWidgetGroup {
                            focus: sidebarRoot.visible
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            // Device selector dialog
                            Item {
                                anchors.fill: parent
                                z: 9999

                                visible: opacity > 0
                                opacity: root.showDeviceSelector ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation { 
                                        duration: Appearance.animation.elementMoveFast.duration
                                        easing.type: Appearance.animation.elementMoveFast.type
                                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                    }
                                }

                                Rectangle { // Scrim
                                    id: scrimOverlay
                                    anchors.fill: parent
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colScrim
                                    MouseArea {
                                        hoverEnabled: true
                                        anchors.fill: parent
                                        preventStealing: true
                                        propagateComposedEvents: false
                                        onClicked: {
                                            root.showDeviceSelector = false
                                        }
                                    }

                                }

                                Rectangle { // The dialog
                                    id: dialog
                                    color: Appearance.colors.colSurfaceContainerHigh
                                    radius: Appearance.rounding.normal
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 30
                                    implicitHeight: dialogColumnLayout.implicitHeight
                                    
                                    ColumnLayout {
                                        id: dialogColumnLayout
                                        anchors.fill: parent
                                        spacing: 16

                                        StyledText {
                                            id: dialogTitle
                                            Layout.topMargin: dialogMargins
                                            Layout.leftMargin: dialogMargins
                                            Layout.rightMargin: dialogMargins
                                            Layout.alignment: Qt.AlignLeft
                                            color: Appearance.m3colors.m3onSurface
                                            font.pixelSize: Appearance.font.pixelSize.larger
                                            text: root.deviceSelectorInput ? Translation.tr("Select input device") : Translation.tr("Select output device")
                                        }

                                        Rectangle {
                                            color: Appearance.m3colors.m3outline
                                            implicitHeight: 1
                                            Layout.fillWidth: true
                                            Layout.leftMargin: dialogMargins
                                            Layout.rightMargin: dialogMargins
                                        }

                                        StyledFlickable {
                                            id: dialogFlickable
                                            Layout.fillWidth: true
                                            clip: true
                                            implicitHeight: Math.min(scrimOverlay.height - dialogMargins * 8 - dialogTitle.height - dialogButtonsRowLayout.height, devicesColumnLayout.implicitHeight)
                                            
                                            contentHeight: devicesColumnLayout.implicitHeight

                                            ColumnLayout {
                                                id: devicesColumnLayout
                                                anchors.fill: parent
                                                Layout.fillWidth: true
                                                spacing: 0

                                                Repeater {
                                                    model: ScriptModel {
                                                        values: Pipewire.nodes.values.filter(node => {
                                                            return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio
                                                        })
                                                    }

                                                    // This could and should be refractored, but all data becomes null when passed wtf
                                                    delegate: StyledRadioButton {
                                                        id: radioButton
                                                        required property var modelData
                                                        Layout.leftMargin: root.dialogMargins
                                                        Layout.rightMargin: root.dialogMargins
                                                        Layout.fillWidth: true

                                                        description: modelData.description
                                                        checked: modelData.id === Pipewire.defaultAudioSink?.id

                                                        Connections {
                                                            target: root
                                                            function onShowDeviceSelectorChanged() {
                                                                if(!root.showDeviceSelector) return;
                                                                radioButton.checked = (modelData.id === Pipewire.defaultAudioSink?.id)
                                                            }
                                                        }

                                                        onCheckedChanged: {
                                                            if (checked) {
                                                                root.selectedDevice = modelData
                                                            }
                                                        }
                                                    }
                                                }
                                                Item {
                                                    implicitHeight: dialogMargins
                                                }
                                            }
                                        }

                                        Rectangle {
                                            color: Appearance.m3colors.m3outline
                                            implicitHeight: 1
                                            Layout.fillWidth: true
                                            Layout.leftMargin: dialogMargins
                                            Layout.rightMargin: dialogMargins
                                        }

                                        RowLayout {
                                            id: dialogButtonsRowLayout
                                            Layout.bottomMargin: dialogMargins
                                            Layout.leftMargin: dialogMargins
                                            Layout.rightMargin: dialogMargins
                                            Layout.alignment: Qt.AlignRight

                                            DialogButton {
                                                buttonText: Translation.tr("Cancel")
                                                onClicked: {
                                                    root.showDeviceSelector = false
                                                }
                                            }
                                            DialogButton {
                                                buttonText: Translation.tr("OK")
                                                onClicked: {
                                                    root.showDeviceSelector = false
                                                    if (root.selectedDevice) {
                                                        if (root.deviceSelectorInput) {
                                                            Pipewire.preferredDefaultAudioSource = root.selectedDevice
                                                        } else {
                                                            Pipewire.preferredDefaultAudioSink = root.selectedDevice
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Device selector
                        ButtonGroup {
                            id: deviceSelectorRowLayout
                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            AudioDeviceSelectorButton {
                                Layout.fillWidth: true
                                input: false
                                onClicked: root.showDeviceSelectorDialog(input)
                            }
                            AudioDeviceSelectorButton {
                                Layout.fillWidth: true
                                input: true
                                onClicked: root.showDeviceSelectorDialog(input)
                            }
                        }

                        BottomWidgetGroup {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: false
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                        }
                    }
                }
            }
        }


    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            if(GlobalStates.sidebarRightOpen) Notifications.timeoutAll();
        }

        function close(): void {
            GlobalStates.sidebarRightOpen = false;
        }

        function open(): void {
            GlobalStates.sidebarRightOpen = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            if(GlobalStates.sidebarRightOpen) Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = true;
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"

        onPressed: {
            GlobalStates.sidebarRightOpen = false;
        }
    }

}
