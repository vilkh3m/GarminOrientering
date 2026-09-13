import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Graphics;
import Toybox.Math;
import Toybox.System;

class poligon1View extends WatchUi.DataField {

    // Theme setting values (see resources/settings/settings.xml)
    private const THEME_AUTO = 0;
    private const THEME_DARK = 1;
    private const THEME_LIGHT = 2;

    // Display modes, chosen in onLayout() depending on the field size
    private const MODE_FULL = 0;     // 4 labelled lines + LAP counter
    private const MODE_COMPACT = 1;  // 2 lines without labels
    private const MODE_MINIMAL = 2;  // 1 line: distance and bearing

    private const EARTH_RADIUS_M = 6371000.0d;

    // Tracking state
    private var lastLapPosition as Position.Location?;
    private var lastPosition as Position.Location?;
    private var distance as Double = 0.0d;
    private var bearing as Double = 0.0d;
    private var totalDistanceFromLap as Double = 0.0d;
    private var lapResetRequested as Boolean = false;
    private var resetCount as Number = 0;
    private var lapStartTime as Number?;
    private var elapsedTime as Number?;
    private var isActivityStarted as Boolean = false;

    // Settings
    private var theme as Number = THEME_DARK;

    // Layout computed in onLayout()
    private var mode as Number = MODE_FULL;
    private var lineFont as FontType = Graphics.FONT_SMALL;
    private var blockTop as Number = 0;
    private var lineHeight as Number = 0;

    function initialize() {
        DataField.initialize();
        loadSettings();
    }

    // Read settings once; called again by the app when the user changes them
    function loadSettings() as Void {
        var value = Application.Properties.getValue("Theme");
        theme = (value instanceof Number) ? value : THEME_DARK;
    }

    // Calculate values (distance, bearing, total distance)
    function compute(info as Activity.Info) as Void {
        var timerState = info.timerState;
        isActivityStarted = timerState != null && timerState != Activity.TIMER_STATE_OFF;
        elapsedTime = info.elapsedTime;

        var current = info.currentLocation;
        if (!isActivityStarted || current == null) {
            return;
        }

        // Set the reference point on LAP press, or on the first GPS fix after start
        if (lapResetRequested || lastLapPosition == null) {
            if (lapResetRequested) {
                resetCount++;
            }
            lapResetRequested = false;
            lastLapPosition = current;
            lastPosition = current;
            totalDistanceFromLap = 0.0d;
            lapStartTime = elapsedTime;
        }

        // Accumulate travelled distance only while the timer is running
        var previous = lastPosition;
        if (timerState == Activity.TIMER_STATE_ON && previous != null) {
            totalDistanceFromLap += calculateDistance(previous, current);
        }
        lastPosition = current;

        var reference = lastLapPosition;
        if (reference != null) {
            distance = calculateDistance(reference, current);
            bearing = calculateBearing(reference, current);
        }
    }

    // Handle LAP button press
    function onTimerLap() as Void {
        lapResetRequested = true;
    }

    // Forget everything when the activity is saved or discarded
    function onTimerReset() as Void {
        lastLapPosition = null;
        lastPosition = null;
        distance = 0.0d;
        bearing = 0.0d;
        totalDistanceFromLap = 0.0d;
        lapResetRequested = false;
        resetCount = 0;
        lapStartTime = null;
    }

    // Pick the display mode and font that fit the current field size
    function onLayout(dc as Dc) as Void {
        var height = dc.getHeight();
        var fonts = [Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY] as Array<FontType>;
        var modes = [MODE_FULL, MODE_COMPACT, MODE_MINIMAL] as Array<Number>;

        for (var m = 0; m < modes.size(); m++) {
            var samples = sampleLines(modes[m]);
            for (var f = 0; f < fonts.size(); f++) {
                var font = fonts[f];
                var fontHeight = dc.getFontHeight(font);
                var footerHeight = (modes[m] == MODE_FULL) ? dc.getFontHeight(Graphics.FONT_XTINY) : 0;
                var blockHeight = samples.size() * fontHeight + footerHeight;
                var top = (height - blockHeight) / 2;

                var fits = top >= 0;
                for (var i = 0; fits && i < samples.size(); i++) {
                    var lineTop = top + i * fontHeight;
                    fits = dc.getTextWidthInPixels(samples[i], font) <= usableWidth(dc, lineTop, lineTop + fontHeight);
                }

                // The smallest option is used when nothing fits
                if (fits || (m == modes.size() - 1 && f == fonts.size() - 1)) {
                    mode = modes[m];
                    lineFont = font;
                    lineHeight = fontHeight;
                    blockTop = top;
                    return;
                }
            }
        }
    }

    // Width available for text centered in the field between two vertical positions.
    // On round screens fields touching the screen edge are cut by the circle, so the
    // field position is estimated from the obscured edges and the circle chord is used.
    private function usableWidth(dc as Dc, top as Number, bottom as Number) as Float {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var flags = getObscurityFlags();
        var settings = System.getDeviceSettings();

        if (settings.screenShape != System.SCREEN_SHAPE_ROUND || flags == 0) {
            return width.toFloat();
        }

        var screenWidth = settings.screenWidth;
        var screenHeight = settings.screenHeight;
        var obscuredLeft = (flags & OBSCURE_LEFT) != 0;
        var obscuredRight = (flags & OBSCURE_RIGHT) != 0;
        var obscuredTop = (flags & OBSCURE_TOP) != 0;
        var obscuredBottom = (flags & OBSCURE_BOTTOM) != 0;

        var offsetY = (screenHeight - height) / 2;
        if (obscuredTop && !obscuredBottom) {
            offsetY = 0;
        } else if (obscuredBottom && !obscuredTop) {
            offsetY = screenHeight - height;
        }

        var centerX = screenWidth / 2.0;
        if (obscuredLeft && !obscuredRight) {
            centerX = width / 2.0;
        } else if (obscuredRight && !obscuredLeft) {
            centerX = screenWidth - width / 2.0;
        }

        var radius = screenHeight / 2.0;
        var distTop = (top + offsetY - radius).abs();
        var distBottom = (bottom + offsetY - radius).abs();
        var dist = (distTop > distBottom) ? distTop : distBottom;
        if (dist >= radius) {
            return 0.0;
        }

        // Half of the text may extend from the field center up to the circle or the field edge
        var halfChord = Math.sqrt(radius * radius - dist * dist);
        var toCircle = halfChord - (centerX - screenWidth / 2.0).abs();
        var toFieldEdge = width / 2.0;
        var half = (toCircle < toFieldEdge) ? toCircle : toFieldEdge;
        return (half > 0) ? (2 * half * 0.95).toFloat() : 0.0;
    }

    // Widest texts each mode can show, so the font does not change while moving
    private function sampleLines(displayMode as Number) as Array<String> {
        if (displayMode == MODE_FULL) {
            return ["Direct: 99999 m", "Total: 99999 m", "Bearing: 359°", "Time: 000:00"];
        } else if (displayMode == MODE_COMPACT) {
            return ["99999 m 359°", "99999 m 000:00"];
        }
        return ["99999 m 359°"];
    }

    // Display update
    function onUpdate(dc as Dc) as Void {
        var backgroundColor = getThemeBackground();
        var textColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(textColor, backgroundColor);
        dc.clear();
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);

        var x = dc.getWidth() / 2;

        if (!isActivityStarted) {
            var middle = dc.getHeight() / 2;
            var font = Graphics.FONT_MEDIUM;
            var halfHeight = dc.getFontHeight(font) / 2;
            if (dc.getTextWidthInPixels("Start Activity", font) > usableWidth(dc, middle - halfHeight, middle + halfHeight)) {
                font = lineFont;
            }
            dc.drawText(x, dc.getHeight() / 2, font, "Start Activity",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var distanceText = distance.format("%.0f") + " m";
        var totalText = totalDistanceFromLap.format("%.0f") + " m";
        var bearingText = bearing.format("%.0f") + "°";
        var timeText = getTimeFromLapText();

        var lines;
        if (mode == MODE_FULL) {
            lines = ["Direct: " + distanceText, "Total: " + totalText, "Bearing: " + bearingText, "Time: " + timeText];
        } else if (mode == MODE_COMPACT) {
            lines = [distanceText + " " + bearingText, totalText + " " + timeText];
        } else {
            lines = [distanceText + " " + bearingText];
        }

        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(x, blockTop + i * lineHeight, lineFont, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }

        if (mode == MODE_FULL) {
            dc.drawText(x, blockTop + lines.size() * lineHeight, Graphics.FONT_XTINY,
                "LAP (" + resetCount.toString() + ")", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function getThemeBackground() as ColorType {
        if (theme == THEME_AUTO) {
            return getBackgroundColor();
        } else if (theme == THEME_LIGHT) {
            return Graphics.COLOR_WHITE;
        }
        return Graphics.COLOR_BLACK;
    }

    private function getTimeFromLapText() as String {
        var start = lapStartTime;
        var now = elapsedTime;
        if (start == null || now == null) {
            return "--:--";
        }
        var timeFromLap = now - start;
        var minutes = timeFromLap / 60000;
        var seconds = (timeFromLap % 60000) / 1000;
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }

    // Great-circle distance in meters
    function calculateDistance(pos1 as Position.Location, pos2 as Position.Location) as Double {
        var p1 = pos1.toRadians();
        var p2 = pos2.toRadians();
        var lat1 = p1[0].toDouble();
        var lat2 = p2[0].toDouble();

        var sinDLat = Math.sin((lat2 - lat1) / 2);
        var sinDLon = Math.sin((p2[1].toDouble() - p1[1].toDouble()) / 2);
        var a = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLon * sinDLon;
        return 2 * EARTH_RADIUS_M * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    // Bearing in degrees (0-360) from pos1 (LAP point) to pos2 (current position)
    function calculateBearing(pos1 as Position.Location, pos2 as Position.Location) as Double {
        var p1 = pos1.toRadians();
        var p2 = pos2.toRadians();
        var lat1 = p1[0].toDouble();
        var lat2 = p2[0].toDouble();
        var dLon = p2[1].toDouble() - p1[1].toDouble();

        var y = Math.sin(dLon) * Math.cos(lat2);
        var x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
        var degrees = Math.toDegrees(Math.atan2(y, x)).toDouble();
        if (degrees < 0) {
            degrees += 360;
        }
        return degrees;
    }
}
