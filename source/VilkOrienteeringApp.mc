import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class VilkOrienteeringApp extends Application.AppBase {

    private var view as VilkOrienteeringView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Data fields do not receive button input, so no input delegate is returned.
    // The reference point is reset with the LAP button (VilkOrienteeringView.onTimerLap).
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var newView = new VilkOrienteeringView();
        view = newView;
        return [ newView ];
    }

    function onSettingsChanged() as Void {
        var currentView = view;
        if (currentView != null) {
            currentView.loadSettings();
        }
        WatchUi.requestUpdate();
    }
}

function getApp() as VilkOrienteeringApp {
    return Application.getApp() as VilkOrienteeringApp;
}
