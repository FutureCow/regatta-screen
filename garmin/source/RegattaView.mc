import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RegattaView extends WatchUi.View {

    private var _remaining as Number?;   // seconden
    private var _running   as Boolean?;
    private var _connected as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Geen XML layout — alles via onUpdate
    }

    // Oproep vanuit RegattaApp.onPhoneMessage
    function update(remaining as Number?, running as Boolean?) as Void {
        _remaining = remaining;
        _running   = running;
        _connected = true;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();   // 454 px op FR965
        var h = dc.getHeight();  // 454 px
        var cx = w / 2;
        var cy = h / 2;

        // Achtergrond
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (!_connected) {
            // Nog geen verbinding met telefoon
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - 20, Graphics.FONT_MEDIUM,
                        WatchUi.loadResource(Rez.Strings.Connecting) as String,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var rem = _remaining != null ? _remaining as Number : 0;

        // Bepaal kleur op basis van resterende tijd
        var timerColor;
        if (_running == true) {
            timerColor = rem > 60 ? Graphics.COLOR_GREEN
                       : rem > 0  ? Graphics.COLOR_ORANGE
                                  : Graphics.COLOR_RED;
        } else {
            timerColor = Graphics.COLOR_LT_GRAY;
        }

        // Teken timer — MM:SS formaat
        var timerStr = formatTime(rem);
        dc.setColor(timerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Graphics.FONT_NUMBER_HOT,
                    timerStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Status label
        var statusStr = (_running == true)
            ? WatchUi.loadResource(Rez.Strings.Running) as String
            : WatchUi.loadResource(Rez.Strings.Paused)  as String;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 55, Graphics.FONT_SMALL,
                    statusStr,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Knophints onderin
        dc.setColor(0x404040, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx - 70, h - 55, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintUp) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx + 70, h - 55, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintDown) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h - 35, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.HintEnter) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
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
