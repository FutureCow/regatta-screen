import Toybox.Lang;
import Toybox.WatchUi;

class ExitConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
