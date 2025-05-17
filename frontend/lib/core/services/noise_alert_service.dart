import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';

class NoiseAlertService {
  static const double noiseThreshold = 85.0;
  static const Duration listeningDuration = Duration(seconds: 10);

  static final NoiseMeter _noiseMeter = NoiseMeter();
  static StreamSubscription<NoiseReading>? _noiseSubscription;

  static Future<bool> listenFor10Seconds() async {
    double rollingAverage = 0.0;
    int count = 0;

    try {
      _noiseSubscription = _noiseMeter.noise.listen(
        (NoiseReading reading) {
          // https://www.linkedin.com/pulse/computing-average-variance-without-arrays-reuven-zalman?trk=public_post
          rollingAverage = (rollingAverage * count + reading.meanDecibel) / (count + 1);
          count++;
        },
      );

      await Future.delayed(listeningDuration);

      await _noiseSubscription?.cancel();
      _noiseSubscription = null;

      if (count > 0) {
        if (rollingAverage > noiseThreshold) {
          debugPrint('Mean noise level exceeded: $rollingAverage dB');
          return true;
        } else {
          debugPrint('Mean noise level safe: $rollingAverage dB');
          return false;
        }
      } else {
        debugPrint('No noise readings');
        return false;
      }
    } catch (error) {
      debugPrint('Error: $error');
      return false;
    } finally {
      await _noiseSubscription?.cancel();
      _noiseSubscription = null;
    }
  }

  static void stopListening() async {
    await _noiseSubscription?.cancel();
    _noiseSubscription = null;
    debugPrint('Stopped listening to noise');
  }
}