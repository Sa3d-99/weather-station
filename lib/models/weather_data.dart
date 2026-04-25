// ─── WeatherData ────────────────────────────────────────────
// Mirrors the ESP32 DataPacket struct:
//   float temp, hum, pres, wind
class WeatherData {
  final double temp;
  final double hum;
  final double pres;
  final double wind;
  final DateTime timestamp;
  final bool isOnline;

  const WeatherData({
    required this.temp,
    required this.hum,
    required this.pres,
    required this.wind,
    required this.timestamp,
    this.isOnline = true,
  });

  factory WeatherData.empty() => WeatherData(
      temp: 0, hum: 0, pres: 0, wind: 0,
      timestamp: DateTime.now(), isOnline: false);

  factory WeatherData.fromMap(Map<dynamic, dynamic> m) => WeatherData(
        temp: (m['temp'] ?? 0).toDouble(),
        hum: (m['hum'] ?? 0).toDouble(),
        pres: (m['pres'] ?? 0).toDouble(),
        wind: (m['wind'] ?? 0).toDouble(),
        timestamp: m['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (m['timestamp'] as num).toInt())
            : DateTime.now(),
        isOnline: m['isOnline'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'temp': temp,
        'hum': hum,
        'pres': pres,
        'wind': wind,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isOnline': isOnline,
      };

  // ── Labels (exact logic from ESP32 .ino) ──
  String get tempLabel {
    if (temp < 0) return 'FREEZING';
    if (temp < 10) return 'COLD';
    if (temp < 18) return 'COOL';
    if (temp < 24) return 'MILD';
    if (temp < 30) return 'WARM';
    return 'HOT';
  }

  String get humLabel {
    if (hum < 30) return 'DRY';
    if (hum < 50) return 'COMFORT';
    if (hum < 70) return 'MODERATE';
    return 'HUMID';
  }

  String get presLabel {
    if (pres > 1020) return 'HIGH-P';
    if (pres >= 1000) return 'NORMAL';
    return 'LOW-P';
  }

  String get windLabel {
    if (wind < 0.5) return 'CALM';
    if (wind < 1.5) return 'LIGHT';
    if (wind < 3.4) return 'BREEZE';
    if (wind < 5.5) return 'GENTLE';
    if (wind < 8.0) return 'MODERATE';
    if (wind < 10.8) return 'FRESH';
    return 'STRONG';
  }

  String get tempEmoji {
    if (temp < 0) return '🥶';
    if (temp < 10) return '❄️';
    if (temp < 18) return '🌤';
    if (temp < 24) return '☀️';
    if (temp < 30) return '🌡';
    return '🔥';
  }

  // Apparent "feels like" temp (Steadman formula simplified)
  double get feelsLike {
    if (temp >= 27 && hum >= 40) {
      // Heat index
      return -8.78469475556 +
          1.61139411 * temp +
          2.33854883889 * hum -
          0.14611605 * temp * hum -
          0.012308094 * temp * temp -
          0.0164248277778 * hum * hum +
          0.002211732 * temp * temp * hum +
          0.00072546 * temp * hum * hum -
          0.000003582 * temp * temp * hum * hum;
    }
    // Wind chill
    if (temp <= 10 && wind > 1.3) {
      return 13.12 +
          0.6215 * temp -
          11.37 * _pow(wind * 3.6, 0.16) +
          0.3965 * temp * _pow(wind * 3.6, 0.16);
    }
    return temp;
  }

  double _pow(double base, double exp) {
    // ignore: unused_local_variable
    double result = 1.0;
    // Simple approximation for small exponents
    return base == 0 ? 0 : _expApprox(exp * _lnApprox(base));
  }

  double _lnApprox(double x) {
    if (x <= 0) return -100;
    double result = 0;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double term = y;
    for (int i = 0; i < 10; i++) {
      result += term / (2 * i + 1);
      term *= y2;
    }
    return 2 * result;
  }

  double _expApprox(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 12; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  // Air Quality index (based on humidity+temp heuristic)
  String get airQualityLabel {
    if (hum > 85 && temp > 25) return 'POOR';
    if (hum > 70 || temp > 35) return 'MODERATE';
    if (hum < 20) return 'DRY-AIR';
    return 'GOOD';
  }

  // Weather condition summary
  String get condition {
    if (pres < 990) return 'STORMY';
    if (pres < 1005 && hum > 80) return 'RAINY';
    if (pres < 1005) return 'CLOUDY';
    if (hum < 30) return 'CLEAR & DRY';
    if (temp > 30 && hum > 60) return 'HOT & HUMID';
    return 'FAIR';
  }
}

// ─── Internet weather from Open-Meteo ───────────────────────
class InternetWeather {
  final double temp;
  final double hum;
  final double windSpeed;
  final double pressure;
  final int weatherCode;
  final String location;
  final DateTime fetchedAt;

  const InternetWeather({
    required this.temp,
    required this.hum,
    required this.windSpeed,
    required this.pressure,
    required this.weatherCode,
    required this.location,
    required this.fetchedAt,
  });

  String get conditionLabel {
    if (weatherCode == 0) return 'CLEAR SKY';
    if (weatherCode <= 3) return 'PARTLY CLOUDY';
    if (weatherCode <= 49) return 'FOGGY';
    if (weatherCode <= 69) return 'DRIZZLE';
    if (weatherCode <= 79) return 'SNOW';
    if (weatherCode <= 99) return 'THUNDERSTORM';
    return 'UNKNOWN';
  }

  String get conditionEmoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 49) return '🌫';
    if (weatherCode <= 69) return '🌧';
    if (weatherCode <= 79) return '❄️';
    if (weatherCode <= 99) return '⛈';
    return '🌡';
  }
}
