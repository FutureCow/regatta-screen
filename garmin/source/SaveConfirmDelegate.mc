import Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.WatchUi;

class SaveConfirmDelegate extends WatchUi.ConfirmationDelegate {

    private var _session as ActivityRecording.Session;

    function initialize(session as ActivityRecording.Session) {
        ConfirmationDelegate.initialize();
        _session = session;
    }

    function onResponse(response as Boolean) as Boolean {
        if (response) {
            _session.save();
        } else {
            _session.discard();
        }
        return true;
    }
}
