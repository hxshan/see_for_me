import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';

import 'Direction.dart';

class Compass {
  StreamSubscription? _subscription;
  double _currentHeading = 0.0;

  // Function to get the current heading (angle in degrees)
  Future<double> getHeading() async {
    return _currentHeading; // Return the current heading in degrees
  }

  // Start listening to compass (magnetometer) sensor
  void startListening() {
    _subscription = magnetometerEvents.listen((MagnetometerEvent event) {
      double angle = _calculateHeadingFromMagnetometer(event);
      _currentHeading = angle; // Store the updated heading
    });
  }

  // Stop listening to the compass sensor
  void stopListening() {
    _subscription?.cancel();
  }

  // Convert magnetometer data to a heading (you might need calibration logic)
  double _calculateHeadingFromMagnetometer(MagnetometerEvent event) {
    // Using event.x, event.y, and event.z to calculate heading
    double heading = atan2(event.y, event.x) * (180 / pi);
    if (heading < 0) {
      heading += 360; // Keep the heading between 0-360 degrees
    }
    return heading;
  }

  // Convert degrees to cardinal direction (N, E, S, W)
  Direction getCardinalDirection(double heading) {
    if (heading >= 315 || heading < 45) {
      return Direction.north;
    } else if (heading >= 45 && heading < 135) {
      return Direction.east;
    } else if (heading >= 135 && heading < 225) {
      return Direction.south;
    } else {
      return Direction.west;
    }
  }
}
