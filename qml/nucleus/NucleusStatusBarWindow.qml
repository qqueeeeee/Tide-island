pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import IslandBackend
import "../bar" as Bar
import "../common" as Common
import "../island" as Island

// The iOS-style status bar owns its own layer-shell surface.
//
// It used to live inside the island's PanelWindow, which meant every geometry
// change of the capsule (expand, notification, capture preview) could drag the
// bar's baseline down with it. A dedicated surface with a fixed height makes
// that structurally impossible: the bar simply cannot move when the island
// grows, because it no longer shares any geometry with it.
PanelWindow {
    id: root

    required property var screenObject
    property var shellRootController: null

    readonly property var userConfig: UserConfig

    // The nucleus island is always the reference idle pill (148 x 34).
    readonly property real islandRestingWidth: 148
    readonly property real islandRestingHeight: 34
    // Mirrors DynamicIslandWindow: the island is a floating capsule now, so even
    // in notch-metrics mode it sits a few px below the screen edge and the bar
    // baseline follows it.
    readonly property real islandTopOffset: Math.max(6, userConfig.islandTopMargin)

    // Where the resting island sits. Bar content is laid out around this fixed
    // rectangle and never around the live capsule.
    readonly property real restingIslandX: Math.round((width - root.islandRestingWidth) / 2)

    readonly property bool compositorIsNiri: CompositorBackend.compositor === "niri"

    screen: screenObject
    color: StyleTokens.transparent
    anchors { top: true; left: true; right: true }
    // The island window reserves the strip; the bar must not reserve a second one.
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: Math.max(1, Math.ceil(bar.requiredWindowHeight))
    visible: userConfig.statusBarEnabled

    mask: Region {
        Region {
            x: Math.floor(bar.leftInputX)
            y: Math.floor(bar.leftInputY)
            width: Math.ceil(bar.leftInputWidth)
            height: Math.ceil(bar.leftInputHeight)
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(bar.rightInputX)
            y: Math.floor(bar.rightInputY)
            width: Math.ceil(bar.rightInputWidth)
            height: Math.ceil(bar.rightInputHeight)
        }
    }

    Island.IslandClock {
        id: clock
        clockFormat: root.userConfig.clockFormat
    }

    Common.HyprlandDispatch {
        id: dispatch
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    readonly property bool sinkMuted: {
        const sink = Pipewire.defaultAudioSink;
        return !!(sink && sink.audio && sink.audio.muted);
    }

    Loader {
        id: workspaceModelLoader

        active: root.userConfig.statusBarEnabled
            && root.userConfig.statusBarShowWorkspaces
            && !root.compositorIsNiri
        asynchronous: false
        source: active ? "BarHyprlandWorkspaceModel.qml" : ""
    }

    Binding {
        target: workspaceModelLoader.item
        property: "screenObject"
        value: root.screenObject
        when: workspaceModelLoader.item !== null
    }

    Bar.StatusBarLayer {
        id: bar

        capsuleX: root.restingIslandX
        capsuleWidth: root.islandRestingWidth
        capsuleY: root.islandTopOffset
        capsuleHeight: root.islandRestingHeight
        capsuleRestingWidth: root.islandRestingWidth
        capsuleRestingHeight: root.islandRestingHeight

        // The bar is always at rest now: it never animates with the island.
        revealProgress: 1
        islandBusy: false

        currentWorkspace: workspaceModelLoader.item
            ? workspaceModelLoader.item.activeWorkspaceId
            : 1
        workspaceIds: workspaceModelLoader.item
            ? workspaceModelLoader.item.workspaceIds
            : []
        workspacesInteractive: !root.compositorIsNiri
        timeText: clock.currentTime
        dateText: clock.currentDateLabel
        batteryCapacity: SysBackend.batteryCapacity
        isCharging: SysBackend.batteryStatus === "Charging" || SysBackend.batteryStatus === "Full"
        isMuted: root.sinkMuted

        onWorkspaceFocusRequested: function(workspaceId) {
            dispatch.focusWorkspace(workspaceId);
        }
    }
}
