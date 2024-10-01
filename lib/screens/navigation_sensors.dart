import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NavigationSensors extends StatefulWidget {
  const NavigationSensors({super.key});

  @override
  State<NavigationSensors> createState() => _NavigationSensorsState();
}

class _NavigationSensorsState extends State<NavigationSensors> {
  double _xRotation = 0.0;
  double _yRotation = 0.0;
  int _stepCount = 0;

  double _azimuth = 0; // Direction the phone is facing in degrees
  String _direction = 'N';

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  List<double> _accelerometerValues = [0.0, 0.0, 0.0];
  List<double> _magnetometerValues = [0.0, 0.0, 0.0];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startCompass();
    // _startSensors();
    // _startStepCounting();
  }

  void _startCompass() {
    // Listen for accelerometer and magnetometer updates
    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      _magnetometerValues = [event.x, event.y, event.z];
      _calculateAzimuth();
    });

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerValues = [event.x, event.y, event.z];
      _calculateAzimuth();
    });
  }

  void _calculateAzimuth() {
    if (_accelerometerValues.isEmpty || _magnetometerValues.isEmpty) return;

    // Normalize the accelerometer values (gravity vector)
    double ax = _accelerometerValues[0];
    double ay = _accelerometerValues[1];
    double az = _accelerometerValues[2];

    double normAcc = sqrt(ax * ax + ay * ay + az * az);
    ax /= normAcc;
    ay /= normAcc;
    az /= normAcc;

    // Normalize the magnetometer values (magnetic field vector)
    double mx = _magnetometerValues[0];
    double my = _magnetometerValues[1];
    double mz = _magnetometerValues[2];

    double normMag = sqrt(mx * mx + my * my + mz * mz);
    mx /= normMag;
    my /= normMag;
    mz /= normMag;

    // Calculate the horizontal component of the magnetic field
    double hx = my * az - mz * ay;
    double hy = mz * ax - mx * az;
    double azimuth = atan2(hy, hx) * (180 / pi); // Convert radians to degrees

    if (azimuth < 0) {
      azimuth += 360; // Ensure azimuth is within 0-360 degrees
    }

    setState(() {
      _azimuth = azimuth;
      _direction = _getCardinalDirection(_azimuth);
    });
  }

  // Convert azimuth in degrees to cardinal directions
  String _getCardinalDirection(double azimuth) {
    if (azimuth >= 337.5 || azimuth < 67.5) {
      return 'N'; // North
    } else if (azimuth >= 67.5 && azimuth < 157.5) {
      return 'E'; // East
    } else if (azimuth >= 157.5 && azimuth < 247.5) {
      return 'S'; // South
    } else if (azimuth >= 247.5 && azimuth < 337.5) {
      return 'W'; // West
    }
    return 'N';
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compass'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Azimuth: ${_azimuth.toStringAsFixed(2)}°',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              'Direction: $_direction',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
