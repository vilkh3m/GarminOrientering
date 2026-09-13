import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class poligon1App extends Application.AppBase {

    private var view as poligon1View?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Data fields do not receive button input, so no input delegate is returned.
    // The reference point is reset with the LAP button (poligon1View.onTimerLap).
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var newView = new poligon1View();
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

function getApp() as poligon1App {
    return Application.getApp() as poligon1App;
}
