/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */
import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

PlasmaCore.ToolTipArea {
    id: root
    objectName: "org.kde.desktop-CompactApplet"
    anchors.fill: parent

    icon: plasmoid.icon
    mainText: plasmoid.toolTipMainText
    subText: plasmoid.toolTipSubText
    location: plasmoid.location
    active: !plasmoid.expanded
    textFormat: plasmoid.toolTipTextFormat
    mainItem: plasmoid.toolTipItem ? plasmoid.toolTipItem : null

    property Item fullRepresentation
    property Item compactRepresentation
    property Item expandedFeedback: expandedItem

    onCompactRepresentationChanged: {
        if (compactRepresentation) {
            compactRepresentation.parent = root;
            compactRepresentation.anchors.fill = root;
            compactRepresentation.visible = true;
        }
        root.visible = true;
    }

    onFullRepresentationChanged: {

        if (!fullRepresentation) {
            return;
        }
        //if the fullRepresentation size was restored to a stored size, or if is dragged from the desktop, restore popup size
        if (fullRepresentation.width > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.width
            })
        } else if (fullRepresentation.Layout && fullRepresentation.Layout.preferredWidth > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.Layout.preferredWidth
            })
        } else if (fullRepresentation.implicitWidth > 0) {
            popupWindow.mainItem.width = Qt.binding(function() {
                return fullRepresentation.implicitWidth
            })
        } else {
            popupWindow.mainItem.width = Qt.binding(function() {
                return theme.mSize(theme.defaultFont).width * 35
            })
        }

        if (fullRepresentation.height > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.height
            })
        } else if (fullRepresentation.Layout && fullRepresentation.Layout.preferredHeight > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.Layout.preferredHeight
            })
        } else if (fullRepresentation.implicitHeight > 0) {
            popupWindow.mainItem.height = Qt.binding(function() {
                return fullRepresentation.implicitHeight
            })
        } else {
            popupWindow.mainItem.height = Qt.binding(function() {
                return theme.mSize(theme.defaultFont).height * 25
            })
        }

        fullRepresentation.parent = appletParent;
        fullRepresentation.anchors.fill = fullRepresentation.parent;
    }

    PlasmaCore.FrameSvgItem {
        id: expandedItem
        anchors.fill: parent
        imagePath: "widgets/tabbar"
        visible: fromCurrentTheme
        prefix: {
            var prefix;
            switch (plasmoid.location) {
                case PlasmaCore.Types.LeftEdge:
                    prefix = "west-active-tab";
                    break;
                case PlasmaCore.Types.TopEdge:
                    prefix = "north-active-tab";
                    break;
                case PlasmaCore.Types.RightEdge:
                    prefix = "east-active-tab";
                    break;
                default:
                    prefix = "south-active-tab";
                }
                if (!hasElementPrefix(prefix)) {
                    prefix = "active-tab";
                }
                return prefix;
            }
        opacity: plasmoid.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }
 
    Timer {
        id: expandedSync
        interval: 100
        onTriggered: plasmoid.expanded = popupWindow.visible;
    }

    Connections {
        target: plasmoid.action("configure")
        onTriggered: plasmoid.expanded = false
    }

    Connections {
        target: plasmoid
        onContextualActionsAboutToShow: root.hideToolTip()
    }

    PlasmaCore.Dialog {
        id: popupWindow
        objectName: "popupWindow"
        flags: Qt.WindowStaysOnTopHint
        visible: plasmoid.expanded && fullRepresentation
        visualParent: compactRepresentation ? compactRepresentation : null
        location: plasmoid.location
        hideOnWindowDeactivate: plasmoid.hideOnWindowDeactivate

        property var oldStatus: PlasmaCore.Types.UnknownStatus

        //It's a MouseEventListener to get all the events, so the eventfilter will be able to catch them
        mainItem: MouseEventListener {
            id: appletParent
            Layout.minimumWidth: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.minimumWidth : 0
            Layout.minimumHeight: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.minimumHeight: 0
            Layout.maximumWidth: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.maximumWidth : Infinity
            Layout.maximumHeight: (fullRepresentation && fullRepresentation.Layout) ? fullRepresentation.Layout.maximumHeight: Infinity

            onActiveFocusChanged: {
                if (activeFocus && fullRepresentation) {
                    fullRepresentation.forceActiveFocus()
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                expandedSync.restart();
                plasmoid.status = oldStatus;
            } else {
                oldStatus = plasmoid.status;
                plasmoid.status = PlasmaCore.Types.RequiresAttentionStatus;
                // This call currently fails and complains at runtime:
                // QWindow::setWindowState: QWindow::setWindowState does not accept Qt::WindowActive
                popupWindow.requestActivate();
            }
        }

    }
}
