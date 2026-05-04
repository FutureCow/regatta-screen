import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

// Stuurt commando's naar de telefoon via Garmin Connect Mobile
class RegattaDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Knop: Start / Enter  →  start/stop timer
    function onSelect() as Boolean {
        sendCommand("start_stop");
        return true;
    }

    // Knop: Up  →  +1 minuut
    function onNextPage() as Boolean {
        sendCommand("plus_one");
        return true;
    }

    // Knop: Down  →  -1 minuut
    function onPreviousPage() as Boolean {
        sendCommand("minus_one");
        return true;
    }

    // Touch: tik op het scherm  →  start/stop
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        var coords = evt.getCoordinates();
        var y = coords[1];
        var h = System.getDeviceSettings().screenHeight;

        // Bovenste 40% scherm = +1, onderste 40% = -1, midden = start/stop
        if (y < h * 0.35f) {
            sendCommand("plus_one");
        } else if (y > h * 0.65f) {
            sendCommand("minus_one");
        } else {
            sendCommand("start_stop");
        }
        return true;
    }

    // Terugknop: sluit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    private function sendCommand(cmd as String) as Void {
        var msg = {"cmd" => cmd} as Dictionary;
        Communications.transmit(msg, null, new Communications.ConnectionListener());
    }
}
