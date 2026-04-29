import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

// Globale referentie zodat inkomende berichten de view kunnen bijwerken
var gView as RegattaView?;

class RegattaApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Registreer voor berichten van de telefoon (via Garmin Connect Mobile)
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    function onStop(state as Dictionary?) as Void {
        gView = null;
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new RegattaView();
        gView = view;
        return [view, new RegattaDelegate()];
    }

    // Inkomend bericht van telefoon: {"remaining": 300, "running": true}
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        if (msg.data instanceof Dictionary) {
            var data = msg.data as Dictionary;
            var remaining = data["remaining"];
            var running   = data["running"];
            if (gView != null) {
                (gView as RegattaView).update(
                    remaining instanceof Number ? remaining as Number : null,
                    running instanceof Boolean  ? running  as Boolean : null
                );
                WatchUi.requestUpdate();
            }
        }
    }
}

function getApp() as RegattaApp {
    return Application.getApp() as RegattaApp;
}
