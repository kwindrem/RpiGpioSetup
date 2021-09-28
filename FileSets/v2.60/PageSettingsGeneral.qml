//////// Modified to add Shutdown command (RPI only)

import QtQuick 1.1
import com.victron.velib 1.0
import "utils.js" as Utils

MbPage
{
	id: root
	property string bindPrefix: "com.victronenergy.settings"

//////// add for Shutdown command
    property string systemBindPrefix: "com.victronenergy.system"
    VBusItem { id: shutdownItem; bind: Utils.path(systemBindPrefix, "/Relay/6/State") }
    VBusItem { id: shutdownItem2; bind: Utils.path(bindPrefix, "/Settings/Relay/6/InitialState") }

	model: VisualItemModel {
		MbItemOptions {
			id: accessLevelSelect
			description: qsTr("Access level")
			bind: Utils.path(bindPrefix, "/Settings/System/AccessLevel")
			magicKeys: true
			writeAccessLevel: User.AccessUser
			possibleValues: [
				MbOption { description: qsTr("User"); value: User.AccessUser; password: "ZZZ" },
				MbOption { description: qsTr("User & Installer"); value: User.AccessInstaller; password: "ZZZ" },
				MbOption { description: qsTr("Superuser"); value: User.AccessSuperUser; readonly: true },
				MbOption { description: qsTr("Service"); value: User.AccessService; readonly: true }
			]

			// touch version to get super user
			property bool pulledDown: listview.contentY < -60
			Timer {
				running: accessLevelSelect.pulledDown
				interval: 5000
				onTriggered: if (user.accessLevel >= User.AccessInstaller) accessLevelSelect.item.setValue(User.AccessSuperUser)
			}

			// change to super user mode if the right button is pressed for a while
			property int repeatCount
			onFocusChanged: repeatCount = 0

			function open() {
				if (user.accessLevel >= User.AccessInstaller && ++repeatCount > 60) {
					if (accessLevelSelect.value !== User.AccessSuperUser)
						accessLevelSelect.item.setValue(User.AccessSuperUser)
					repeatCount = 0
				}
			}
		}

		MbEditBox {
			show: user.accessLevel >= User.AccessSuperUser
			description: "Set root password"
			onEditDone: {
				if (newValue.length < 6) {
					toast.createToast("Please enter at least 6 characters")
				} else {
					toast.createToast(vePlatform.setRootPassword(newValue))
					item.value = ""
				}
			}
		}

		MbSwitch {
			name: qsTr("SSH on LAN")
			show: user.accessLevel >= User.AccessSuperUser
			bind: "com.victronenergy.settings/Settings/System/SSHLocal"
		}

		MbSwitch {
			id: remoteSupportOnOff
			name: qsTr("Remote support")
			bind: "com.victronenergy.settings/Settings/System/RemoteSupport"
		}

		MbItemValue {
			description: qsTr("Remote support tunnel")
			item.value: remotePort.item.valid && remotePort.item.value !== 0 ? qsTr("Online") : qsTr("Offline")
			show: remoteSupportOnOff.item.value
		}

		MbItemValue {
			id: remotePort
			description: qsTr("Remote support IP and port")
			item.bind: "com.victronenergy.settings/Settings/System/RemoteSupportIpAndPort"
			show: remoteSupportOnOff.item.value
		}

		MbOK {
			id: reboot
			description: qsTr("Reboot?")
			writeAccessLevel: User.AccessUser
			onClicked: {
				toast.createToast(qsTr("Rebooting..."), 10000, "icon-restart-active")
				vePlatform.reboot()
			}
		}
//////// add for Shutdown command
        // shutdown uses a psudo relay output connected to a psudo digital input
        // shutdownItem is the relay state in system
        // shutdownItem2 is the relay innitial state in settings
        // the latter must not remain set through the shutdown or the system
        // will shutdown immediately on startup!!!
        MbOK {
            id: shutdown
            description: qsTr("Shutdown?")
            writeAccessLevel: User.AccessUser
            onClicked:
            {
                toast.createToast(qsTr("Shutting down..."), 10000, "icon-restart-active")
                if (shutdownItem.valid)
                    shutdownItem.setValue (1)
                if (shutdownItem2.valid)
                    shutdownItem2.setValue (0)
            }
        }

		MbSwitch {
			property VBusItem hasBuzzer: VBusItem {bind: "com.victronenergy.system/Buzzer/State"}
			name: qsTr("Audible alarm")
			bind: Utils.path(bindPrefix, "/Settings/Alarm/Audible")
			show: hasBuzzer.valid
		}

		MbItemOptions {
			id: demoOnOff
			description: qsTr("Demo mode")
			bind: Utils.path(bindPrefix, "/Settings/Gui/DemoMode")
			possibleValues: [
				MbOption { description: qsTr("Disabled"); value: 0 },
				MbOption { description: qsTr("ESS demo"); value: 1 },
				MbOption { description: qsTr("Boat/Motorhome demo 1"); value: 2 },
				MbOption { description: qsTr("Boat/Motorhome demo 2"); value: 3 }
			]
		}

		MbItemText {
			text: qsTr("Starting demo mode will change some settings and the user interface will be unresponsive for a moment.")
			wrapMode: Text.WordWrap
		}
	}
}
