import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Graphics;
import Toybox.Math;

class poligon1View extends WatchUi.DataField {

    // Version and author information
    private const APP_VERSION = "1.0.0";
    private const APP_AUTHOR = "Dominik Pietrzak";
    private const APP_NAME = "GPS Tracker";

    // Class field variables declaration
    private var lastLapPosition as Position.Location?;
    private var distance as Float;
    private var bearing as Float;
    private var isActivityStarted as Boolean;
    private var lapResetRequested as Boolean;
    private var lastLapTime as Number?;
    private var resetCount as Number;
    private var totalDistanceFromLap as Float;
    private var lastPosition as Position.Location?;
    private var lapStartTime as Number?;
    private var currentInfo as Activity.Info?;

    // Data Field initialization
    function initialize() {
        DataField.initialize();
        lastLapPosition = null;
        distance = 0.0;
        bearing = 0.0;
        isActivityStarted = false;
        lapResetRequested = false;
        lastLapTime = null;
        resetCount = 0;
        totalDistanceFromLap = 0.0;
        lastPosition = null;
        lapStartTime = null;
        currentInfo = null;
    }

    // Calculate values (distance and bearing)
    function compute(info as Activity.Info) as Numeric? {
        // Save current info for use in onUpdate
        currentInfo = info;

        // Check if activity is started
        if (info.currentLocation != null) {
            isActivityStarted = true;
        } else {
            isActivityStarted = false;
        }

        // Check if LAP reset occurred
        if (lapResetRequested && info.currentLocation != null) {
            lastLapPosition = info.currentLocation;
            lastPosition = info.currentLocation;
            totalDistanceFromLap = 0.0;
            lapStartTime = info.elapsedTime;
            lapResetRequested = false;
            resetCount = resetCount + 1;
        }

        // Check if new lap occurred by activity time change
        if (info.elapsedTime != null && lastLapTime != null && info.elapsedTime < lastLapTime && info.currentLocation != null) {
            // Activity time reset - new lap may have occurred
            lastLapPosition = info.currentLocation;
            lastPosition = info.currentLocation;
            totalDistanceFromLap = 0.0;
            lapStartTime = info.elapsedTime;
        }
        lastLapTime = info.elapsedTime;

        // If no reference point yet but GPS available, set first point
        if (lastLapPosition == null && info.currentLocation != null && isActivityStarted) {
            lastLapPosition = info.currentLocation;
            lastPosition = info.currentLocation;
            totalDistanceFromLap = 0.0;
            lapStartTime = info.elapsedTime;
        }

        // Calculate total distance from LAP
        if (isActivityStarted && lastPosition != null && info.currentLocation != null) {
            var segmentDistance = calculateDistance(lastPosition, info.currentLocation);
            totalDistanceFromLap += segmentDistance;
            lastPosition = info.currentLocation;
        }

        // Calculate distance and bearing
        if (isActivityStarted && lastLapPosition != null && info.currentLocation != null) {
            distance = calculateDistance(lastLapPosition, info.currentLocation);
            bearing = calculateBearing(lastLapPosition, info.currentLocation);
        } else {
            distance = 0.0;
            bearing = 0.0;
        }

        // Set value for Data Field
        // In SimpleDataField, value is automatically displayed
        return distance;
    }

    // Display update
    function onUpdate(dc as Graphics.Dc) as Void {
        // Read Dark Mode setting from properties
        var darkMode = Application.Properties.getValue("DarkMode");


        // If null (not set by user), use default value from properties.xml (true)
        if (darkMode == null) {
            darkMode = true;
        }

        // Set colors based on Dark Mode setting
        var backgroundColor = darkMode ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        var textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        // Clear screen with selected colors
        dc.setColor(textColor, backgroundColor);
        dc.clear();

        // Set text colors
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);

        // Text positions
        var x = dc.getWidth() / 2;
        var y1 = dc.getHeight() / 7;
        var y2 = (dc.getHeight() * 1.7) / 7;
        var y3 = (dc.getHeight() * 2.7) / 7;
        var y4 = (dc.getHeight() * 3.5) / 7;

        if (!isActivityStarted) {
            // If activity is not started
            dc.drawText(x, dc.getHeight() / 2, Graphics.FONT_MEDIUM, "Start Activity", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Calculate time from LAP
            var timeFromLapText = "---";
            if (lapStartTime != null && currentInfo != null && currentInfo.elapsedTime != null) {
                var timeFromLap = currentInfo.elapsedTime - lapStartTime;
                var minutes = (timeFromLap / 60000).toNumber();
                var seconds = ((timeFromLap % 60000) / 1000).toNumber();
                timeFromLapText = minutes.format("%02d") + ":" + seconds.format("%02d");
            }

            // Format data
            var distanceText = "Direct: " + distance.format("%.0f") + " m";
            var totalDistanceText = "Total: " + totalDistanceFromLap.format("%.0f") + " m";
            var bearingText = "Bearing: " + bearing.format("%.0f") + "°";
            var timeText = "Time: " + timeFromLapText;

            // Draw text
            dc.drawText(x, y1, Graphics.FONT_SMALL, distanceText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y2, Graphics.FONT_SMALL, totalDistanceText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y3, Graphics.FONT_SMALL, bearingText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y4, Graphics.FONT_SMALL, timeText, Graphics.TEXT_JUSTIFY_CENTER);

            // Additional information about reset and counter
            var statusText = "LAP (" + resetCount.toString() + ")";
            dc.drawText(x, dc.getHeight() - 40, Graphics.FONT_XTINY, statusText, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Handle LAP button press
    function onTimerLap() as Void {
        lapResetRequested = true;
    }

    // Public method to reset LAP position
    function resetLapPosition() as Void {
        lapResetRequested = true;
    }

    // Calculate distance (in meters)
    function calculateDistance(pos1 as Position.Location, pos2 as Position.Location) as Float {
        var lat1 = pos1.toRadians()[0];
        var lon1 = pos1.toRadians()[1];
        var lat2 = pos2.toRadians()[0];
        var lon2 = pos2.toRadians()[1];

        var R = 6371000.0; // Earth radius in meters
        var dLat = lat2 - lat1;
        var dLon = lon2 - lon1;

        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat1) * Math.cos(lat2) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        var distance = R * c;

        return distance;
    }

    // Calculate bearing (in degrees)
    function calculateBearing(pos1 as Position.Location, pos2 as Position.Location) as Float {
        var lat1 = pos1.toRadians()[0];
        var lon1 = pos1.toRadians()[1];
        var lat2 = pos2.toRadians()[0];
        var lon2 = pos2.toRadians()[1];

        var dLon = lon2 - lon1;

        var y = Math.sin(dLon) * Math.cos(lat2);
        var x = Math.cos(lat1) * Math.sin(lat2) -
                Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon);
        var bearing = Math.atan2(y, x);

        // Convert to degrees and normalize to 0-360
        bearing = Math.toDegrees(bearing).toFloat();
        while (bearing < 0.0) {
            bearing += 360.0;
        }
        while (bearing >= 360.0) {
            bearing -= 360.0;
        }

        return bearing;
    }
}