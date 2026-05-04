import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

var gView as RegattaView?;

class RegattaApp extends Application.AppBase {

    private var _remaining       as Number  = 0;
    private var _running         as Boolean = false;
    private var _connected       as Boolean = false;
    private var _timer           as Timer.Timer?;
    private var _session         as ActivityRecording.Session?;
    // true zodra opname éénmaal gestart is; voorkomt herstart en dubbele stop
    private var _recordingActive as Boolean = false;
    // voorkomt dat confirmation meerdere keren verschijnt
    private var _confirmShown    as Boolean = false;

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
        // App sluit: gooi actieve opname weg zonder bevestiging
        if (_session != null) {
            try {
                (_session as ActivityRecording.Session).stop();
                (_session as ActivityRecording.Session).discard();
            } catch (ex) {}
            _session = null;
        }
        gView = null;
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new RegattaView();
        gView = view;
        return [view, new RegattaDelegate()];
    }

    function onTick() as Void {
        if (_running) {
            _remaining -= 1;
        }
        _checkRecording();
        _refreshView();
    }

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

        if (isKeyMoment || runChanged || bigDrift || !_connected) {
            // Overschrijf lokale elapsed time (negatief) nooit met telefoon's 0
            if (!(phoneRem == 0 && _remaining < 0)) {
                _remaining = phoneRem;
            }
            _running   = phoneRunning;
            _connected = true;
        }

        _checkRecording();
        _refreshView();
    }

    // Directe lokale aanpassing bij knopdruk — telefoon synct de exacte waarde kort daarna
    function toggleRunning() as Void {
        _running = !_running;
        _checkRecording();
        _refreshView();
    }

    function roundUp() as Void {
        var mins = _remaining / 60;
        var secs = _remaining % 60;
        _remaining = (secs != 0) ? (mins + 1) * 60 : _remaining + 60;
        _refreshView();
    }

    function roundDown() as Void {
        _remaining = (_remaining / 60) * 60;
        _refreshView();
    }

    private function _checkRecording() as Void {
        // Start opname eenmalig: timer loopt en <= 5 min resterend
        if (_running && _remaining <= 300 && !_recordingActive) {
            _recordingActive = true;
            _confirmShown    = false;
            _startRecording();
        }

        // Stop en vraag bevestiging: timer gestopt, opname was actief, nog niet gevraagd
        if (!_running && _recordingActive && _session != null && !_confirmShown) {
            _confirmShown = true;
            _stopAndAskSave();
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
            _session         = null;
            _recordingActive = false;
        }
    }

    private function _stopAndAskSave() as Void {
        if (_session == null) { return; }
        var s = _session as ActivityRecording.Session;
        _session = null;
        try {
            s.stop();
            var confirm = new WatchUi.Confirmation("Activiteit opslaan?");
            WatchUi.pushView(confirm, new SaveConfirmDelegate(s), WatchUi.SLIDE_UP);
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
