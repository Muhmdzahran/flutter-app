import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:vibration/vibration.dart';

class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  double? _heading;
  double? _qiblaDirection;
  Position? _position;
  bool _hasVibrated = false; // Prevent continuous vibration

  @override
  void initState() {
    super.initState();
    _getLocation();
    FlutterCompass.events!.listen((event) {
      if (event.heading != null) {
        setState(() => _heading = event.heading);
      }
    });
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    _position = await Geolocator.getCurrentPosition();
    _calculateQiblaDirection();
  }

  void _calculateQiblaDirection() {
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;

    final userLat = _position!.latitude;
    final userLon = _position!.longitude;

    final userLatRad = vm.radians(userLat);
    final userLonRad = vm.radians(userLon);
    final kaabaLatRad = vm.radians(kaabaLat);
    final kaabaLonRad = vm.radians(kaabaLon);

    final deltaLon = kaabaLonRad - userLonRad;
    final y = sin(deltaLon);
    final x =
        cos(userLatRad) * tan(kaabaLatRad) - sin(userLatRad) * cos(deltaLon);
    final bearing = (vm.degrees(atan2(y, x)) + 360) % 360;

    setState(() => _qiblaDirection = bearing);
  }

  @override
  Widget build(BuildContext context) {
    final qiblaAngle = (_qiblaDirection ?? 0) - (_heading ?? 0);
    final normalizedAngle = (qiblaAngle + 360) % 360;
    final isFacingQibla = normalizedAngle.abs() < 1 || normalizedAngle > 359;

    // 🔔 Vibrate once when aligned
    if (isFacingQibla && !_hasVibrated) {
      Vibration.vibrate(duration: 300);
      _hasVibrated = true;
    } else if (!isFacingQibla) {
      _hasVibrated = false;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Qibla Compass")),
      body: Center(
        child: _heading == null || _qiblaDirection == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating compass
                      Transform.rotate(
                        angle: vm.radians(normalizedAngle),
                        child: Image.asset('assets/compass.png', width: 250),
                      ),
                      // Fixed Kaaba arrow
                      Image.asset('assets/kaaba_arrow.png',
                          width: 80, height: 80),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isFacingQibla
                        ? "✅ You’re precisely facing the Qibla!"
                        : "🕋 Rotate your phone slowly...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isFacingQibla ? Colors.green : Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Angle to Qibla: ${normalizedAngle.toStringAsFixed(1)}°",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }
}
