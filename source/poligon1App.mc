import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class poligon1BehaviorDelegate extends WatchUi.BehaviorDelegate {
    private var dataField as poligon1View;

    function initialize(df as poligon1View) {
        BehaviorDelegate.initialize();
        dataField = df;
    }

    function onSelect() as Boolean {
        dataField.resetLapPosition();
        return true;
    }
}

class poligon1App extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new poligon1View();
        var delegate = new poligon1BehaviorDelegate(view);
        return [ view, delegate ];
    }
}

function getApp() as poligon1App {
    return Application.getApp() as poligon1App;
}