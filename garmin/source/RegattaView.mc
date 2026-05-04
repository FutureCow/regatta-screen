import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RegattaView extends WatchUi.View {

    private var _remaining as Number = 0;
    private var _running   as Boolean = false;
    private var _connected as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function update(remaining as Number, running as Boolean, connected as Boolean) as Void {
        _remaining = remaining;
        _running   = running;
        _connected = connected;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w  = dc.getWidth();
        var h  = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (!_connected) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM,
                        WatchUi.loadResource(Rez.Strings.Connecting) as String,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Na 0:00 telt de watch als elapsed time op
        var elapsed = _running && _remaining < 0;

        // Timerkleur
        var timerColor;
        if (elapsed) {
            timerColor = Graphics.COLOR_RED;
        } else if (_running) {
            timerColor = _remaining > 60 ? Graphics.COLOR_GREEN
                       : _remaining > 0  ? Graphics.COLOR_ORANGE
                                         : Graphics.COLOR_RED;
        } else {
            timerColor = Graphics.COLOR_LT_GRAY;
        }

        // Timer MM:SS (na 0:00 tonen als +mm:ss)
        var timeStr = elapsed
            ? ("+" + formatTime(-_remaining))
            : formatTime(_remaining);
        dc.setColor(timerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT,
                    timeStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Status
        var statusStr = elapsed
            ? (WatchUi.loadResource(Rez.Strings.Running) as String)
            : (_running
                ? WatchUi.loadResource(Rez.Strings.Running) as String
                : WatchUi.loadResource(Rez.Strings.Paused)  as String);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 55, Graphics.FONT_SMALL,
                    statusStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Knophints — +1/-1 links, start/stop rechtsboven (FR965)
        dc.setColor(0x404040, Graphics.COLOR_TRANSPARENT);
        dc.drawText(30, cy - 20, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintUp) as String,
                    Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(30, cy + 80, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintDown) as String,
                    Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(w - 30, 50, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintEnter) as String,
                    Graphics.TEXT_JUSTIFY_RIGHT);
    }

    private function formatTime(totalSec as Number) as String {
        var negative = totalSec < 0;
        var abs = negative ? -totalSec : totalSec;
        var minutes = abs / 60;
        var seconds = abs % 60;
        var sign = negative ? "-" : "";
        return Lang.format("$1$$2$:$3$", [
            sign,
            minutes.format("%02d"),
            seconds.format("%02d")
        ]);
    }
}
