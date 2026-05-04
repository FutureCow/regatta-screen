import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class TimerMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as Symbol;
        var cmd as String;
        if (id == :five) {
            cmd = "set_5";
        } else if (id == :ten) {
            cmd = "set_10";
        } else {
            cmd = "set_15";
        }
        var msg = {"cmd" => cmd} as Dictionary;
        Communications.transmit(msg, null, new Communications.ConnectionListener());
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
