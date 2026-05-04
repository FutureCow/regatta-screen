import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

var gView as RegattaView?;

class RegattaApp extends Application.AppBase {

    private var _remaining as Number = 0;
    private var _running   as Boolean = false;
    private var _timer     as Timer.Timer?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), 1000, true);
    }

    function onStop(state as Dictionary?) as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
        }
        gView = null;
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new RegattaView();
        gView = view;
        return [view, new RegattaDelegate()];
    }

    // Lokale tick — telt af zodat het scherm vloeiend loopt tussen telefoonberichten
    function onTick() as Void {
        if (_running && _remaining > 0) {
            _remaining -= 1;
        }
        if (gView != null) {
            (gView as RegattaView).update(_remaining, _running, true);
            WatchUi.requestUpdate();
        }
    }

    // Sync vanuit telefoon — overschrijft lokale teller
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        if (msg.data instanceof Dictionary) {
            var data = msg.data as Dictionary;
            var remaining = data["remaining"];
            var running   = data["running"];
            if (remaining instanceof Number) { _remaining = remaining as Number; }
            if (running instanceof Boolean)  { _running   = running  as Boolean; }
            if (gView != null) {
                (gView as RegattaView).update(_remaining, _running, true);
                WatchUi.requestUpdate();
            }
        }
    }
}

function getApp() as RegattaApp {
    return Application.getApp() as RegattaApp;
}
