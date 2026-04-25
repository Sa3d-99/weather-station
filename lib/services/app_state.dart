import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../services/firebase_service.dart';
import '../services/location_weather_service.dart';

class AppState extends ChangeNotifier {
  final _firebase = FirebaseService();
  final _locSvc   = LocationWeatherService();

  WeatherData       _live    = WeatherData.empty();
  WeatherData?      _prev;
  List<WeatherData> _history = [];
  InternetWeather?  _internet;
  int               _frameCount = 0;
  String            _error      = '';
  bool              _locationLoading = true;

  StreamSubscription<WeatherData>?       _liveSub;
  StreamSubscription<List<WeatherData>>? _histSub;
  Timer?                                 _internetTimer;

  WeatherData       get live            => _live;
  WeatherData?      get prev            => _prev;
  List<WeatherData> get history         => _history;
  InternetWeather?  get internet        => _internet;
  int               get frameCount      => _frameCount;
  String            get locationName    => _locSvc.locationName;
  String            get error           => _error;
  bool              get locationLoading => _locationLoading;
  bool              get locationDeniedForever => _locSvc.permissionDeniedForever;

  Future<void> init() async {
    // ── Firebase live stream — updates every ~1 second ──────────
    _liveSub = _firebase.liveStream.listen(
      (d) {
        _prev = _live;
        _live = d;
        _frameCount++;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Firebase: $e';
        notifyListeners();
      },
    );

    // ── Firebase history stream ──────────────────────────────────
    _histSub = _firebase.historyStream.listen((list) {
      _history = list;
      notifyListeners();
    });

    // ── Location (runs in parallel, won't block Firebase) ────────
    _locationLoading = true;
    notifyListeners();

    _locSvc.init().then((_) async {
      _locationLoading = false;
      notifyListeners();
      await _refreshInternet();
    });

    // Auto-refresh internet weather every 10 minutes
    _internetTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _refreshInternet(),
    );
  }

  Future<void> _refreshInternet() async {
    final w = await _locSvc.fetchInternetWeather();
    if (w != null) {
      _internet = w;
      notifyListeners();
    }
  }

  Future<void> pushTestData(WeatherData d) => _firebase.pushData(d);

  Future<void> refreshInternet() => _refreshInternet();

  /// Re-attempt location after user grants permission in settings
  Future<void> retryLocation() async {
    _locationLoading = true;
    notifyListeners();
    await _locSvc.init();
    _locationLoading = false;
    notifyListeners();
    await _refreshInternet();
  }

  Future<void> openLocationSettings() => _locSvc.openLocationSettings();
  Future<void> openAppSettings()      => _locSvc.openSettings();

  @override
  void dispose() {
    _liveSub?.cancel();
    _histSub?.cancel();
    _internetTimer?.cancel();
    super.dispose();
  }
}
