import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

var gView as RegattaView?;

class RegattaApp extends Application.AppBase {

    private var _remaining as Number = 0;
    private var _running   as Boolean = false;
    private var _connected as Boolean = false;
    private var _timer     as Timer.Timer?;
    private var _session   as ActivityRecording.Session?;

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
        _stopRecording(false);
        gView = null;
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new RegattaView();
        gView = view;
        return [view, new RegattaDelegate()];
    }

    // Lokale tick — telt af/op zodat het scherm vloeiend loopt
    function onTick() as Void {
        if (_running) {
            _remaining -= 1;
        }
        _updateRecording();
        _refreshView();
    }

    // Sync vanuit telefoon — alleen bij sleutelmomenten of statuswijziging
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        if (!(msg.data instanceof Dictionary)) { return; }
        var data    = msg.data as Dictionary;
        var remData = data["remaining"];
        var runData = data["running"];
        if (!(remData instanceof Number) || !(runData instanceof Boolean)) { return; }

        var phoneRem     = remData as Number;
        var phoneRunning = runData as Boolean;
        var runChanged   = (phoneRunning != _running);
        var isKeyMoment  = (phoneRem == 900 || phoneRem == 600 || phoneRem == 300);
        var bigDrift     = (_remaining - phoneRem).abs() > 10;

        // Accepteer sync bij sleutelmomenten, statuswijziging, grote afwijking, of eerste verbinding
        if (isKeyMoment || runChanged || bigDrift || !_connected) {
            _remaining = phoneRem;
            _running   = phoneRunning;
            _connected = true;
        }

        _updateRecording();
        _refreshView();
    }

    // Start GPS opname als zeilen activiteit wanneer <= 5 min resterend en timer loopt
    private function _updateRecording() as Void {
        if (_running && _remaining <= 300 && _session == null) {
            _startRecording();
        }
        if (!_running && _session != null) {
            _stopRecording(true);
        }
    }

    private function _startRecording() as Void {
        try {
            _session = ActivityRecording.createSession({
                :name     => "Zeilen",
                :sport    => Activity.SPORT_SAILING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            (_session as ActivityRecording.Session).start();
        } catch (ex) {
            _session = null;
        }
    }

    private function _stopRecording(save as Boolean) as Void {
        if (_session == null) { return; }
        var s = _session as ActivityRecording.Session;
        _session = null;
        try {
            s.stop();
            if (save) {
                // Bevestiging vragen vóór opslaan
                var confirm = new WatchUi.Confirmation("Activiteit opslaan?");
                WatchUi.pushView(confirm, new SaveConfirmDelegate(s), WatchUi.SLIDE_UP);
            } else {
                s.discard();
            }
        } catch (ex) {}
    }

    private function _refreshView() as Void {
        if (gView != null) {
            (gView as RegattaView).update(_remaining, _running, _connected);
            WatchUi.requestUpdate();
        }
    }
}

function getApp() as RegattaApp {
    return Application.getApp() as RegattaApp;
}
