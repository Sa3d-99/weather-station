import 'package:firebase_database/firebase_database.dart';
import '../models/weather_data.dart';

class FirebaseService {
  final _liveRef     = FirebaseDatabase.instance.ref('weather_station');
  final _historyRef  = FirebaseDatabase.instance.ref('weather_history');

  // ── Live stream ──────────────────────────────────────────────
  Stream<WeatherData> get liveStream => _liveRef.onValue.map((e) {
        final v = e.snapshot.value as Map<dynamic, dynamic>?;
        if (v == null) return WeatherData.empty();
        return WeatherData.fromMap(v);
      });

  // ── History stream (last 48 readings) ────────────────────────
  Stream<List<WeatherData>> get historyStream =>
      _historyRef.orderByChild('timestamp').limitToLast(48).onValue.map((e) {
        if (!e.snapshot.exists) return <WeatherData>[];
        final map = e.snapshot.value as Map<dynamic, dynamic>;
        return (map.values
                .map((v) => WeatherData.fromMap(v as Map<dynamic, dynamic>))
                .toList()
              ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
      });

  // ── Write current reading (from test panel) ──────────────────
  Future<void> pushData(WeatherData d) async {
    await _liveRef.set(d.toMap());
    await _historyRef.push().set(d.toMap());
  }
}
