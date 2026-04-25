import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

class HeroPanel extends StatefulWidget {
  final WeatherData live;
  final InternetWeather? internet;
  final String locationName;
  final bool isOnline;
  final int frameCount;
  final bool locationLoading;
  final bool locationDeniedForever;

  const HeroPanel({
    super.key,
    required this.live,
    required this.locationName,
    required this.isOnline,
    required this.frameCount,
    this.internet,
    this.locationLoading = false,
    this.locationDeniedForever = false,
  });

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  late final Stream<int> _ticker =
      Stream.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.heroAcc.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.heroAcc.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 2)
        ],
      ),
      child: Column(children: [
        // ── Row 1: Location + online status ────────────────────
        Row(children: [
          const Icon(Icons.location_on, color: AppTheme.heroAcc, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: widget.locationLoading
                ? Text('Locating...',
                    style: GoogleFonts.orbitron(
                        color: AppTheme.heroAcc.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 1.5))
                : GestureDetector(
                    // Tap location name to retry / open settings
                    onTap: () {
                      final state = context.read<AppState>();
                      if (widget.locationDeniedForever) {
                        state.openAppSettings();
                      } else if (widget.locationName == 'Location Denied' ||
                          widget.locationName == 'GPS Off' ||
                          widget.locationName == 'Location Error') {
                        state.retryLocation();
                      }
                    },
                    child: Row(children: [
                      Flexible(
                        child: Text(widget.locationName,
                            style: GoogleFonts.orbitron(
                                color: _locationColor,
                                fontSize: 10,
                                letterSpacing: 1.5),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (_showRetryIcon) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.locationDeniedForever
                              ? Icons.settings_outlined
                              : Icons.refresh,
                          color: AppTheme.offline,
                          size: 11,
                        ),
                      ]
                    ]),
                  ),
          ),
          _StatusDot(isOnline: widget.isOnline),
          const SizedBox(width: 5),
          Text(widget.isOnline ? 'ONLINE' : 'OFFLINE',
              style: GoogleFonts.orbitron(
                  color:
                      widget.isOnline ? AppTheme.online : AppTheme.offline,
                  fontSize: 9,
                  letterSpacing: 1.5)),
        ]),

        const SizedBox(height: 12),

        // ── Row 2: Big temperature + Live clock ────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Temperature block
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.live.temp.toStringAsFixed(1),
                style: GoogleFonts.orbitron(
                    color: AppTheme.colTemp,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    height: 1),
              ).animate(key: ValueKey(widget.live.temp.toStringAsFixed(1)))
               .fadeIn(duration: 250.ms),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('°C',
                    style: GoogleFonts.orbitron(
                        color: AppTheme.colTemp.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w300)),
              ),
            ]),
            Text(widget.live.tempLabel,
                style: GoogleFonts.orbitron(
                    color: AppTheme.heroAcc, fontSize: 10, letterSpacing: 2)),
            Text(
                'FEELS ${widget.live.feelsLike.toStringAsFixed(1)}°C  •  ${widget.live.condition}',
                style: GoogleFonts.shareTechMono(
                    color: AppTheme.subtext, fontSize: 9)),
          ]),

          const Spacer(),

          // Clock + date + internet badge
          StreamBuilder<int>(
            stream: _ticker,
            builder: (_, __) {
              final now = DateTime.now();
              return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(DateFormat('hh:mm:ss a').format(now),
                    style: GoogleFonts.orbitron(
                        color: AppTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                Text(DateFormat('EEEE, MMM d').format(now),
                    style: GoogleFonts.shareTechMono(
                        color: AppTheme.subtext, fontSize: 11)),
                const SizedBox(height: 8),
                if (widget.internet != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.internet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppTheme.internet.withOpacity(0.4)),
                    ),
                    child: Text(
                      '🌐 ${widget.internet!.temp.toStringAsFixed(1)}°C  ${widget.internet!.conditionEmoji}',
                      style: GoogleFonts.orbitron(
                          color: AppTheme.internet, fontSize: 10),
                    ),
                  ),
              ]);
            },
          ),
        ]),

        const SizedBox(height: 10),
        const Divider(color: AppTheme.divider, height: 1),
        const SizedBox(height: 8),

        // ── Row 3: Quick chips ──────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _chip('💧', '${widget.live.hum.toStringAsFixed(0)}%',
              AppTheme.colHum),
          _chip('🌬', '${widget.live.wind.toStringAsFixed(1)} m/s',
              AppTheme.colWind),
          _chip('⬆', '${(widget.live.pres / 10).toStringAsFixed(1)} kPa',
              AppTheme.colPres),
          _chip('🌡', widget.live.airQualityLabel,
              _aqColor(widget.live.airQualityLabel)),
          _chip('F:', '${widget.frameCount % 9999}',
              AppTheme.subtext.withOpacity(0.4)),
        ]),
      ]),
    );
  }

  Color get _locationColor {
    if (widget.locationName == 'GPS Off' ||
        widget.locationName == 'Location Denied' ||
        widget.locationName == 'Open Settings' ||
        widget.locationName == 'Location Error' ||
        widget.locationName == 'GPS Timeout') {
      return AppTheme.offline;
    }
    return AppTheme.heroAcc;
  }

  bool get _showRetryIcon {
    return widget.locationName == 'GPS Off' ||
        widget.locationName == 'Location Denied' ||
        widget.locationName == 'Open Settings' ||
        widget.locationName == 'Location Error' ||
        widget.locationName == 'GPS Timeout';
  }

  Widget _chip(String icon, String val, Color c) => Column(children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(val,
            style: GoogleFonts.shareTechMono(color: c, fontSize: 9)),
      ]);

  Color _aqColor(String label) {
    if (label == 'GOOD') return AppTheme.online;
    if (label == 'MODERATE') return AppTheme.heroAcc;
    return AppTheme.offline;
  }
}

class _StatusDot extends StatelessWidget {
  final bool isOnline;
  const _StatusDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final c = isOnline ? AppTheme.online : AppTheme.offline;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [BoxShadow(color: c.withOpacity(0.7), blurRadius: 6)]),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .fadeOut(duration: 900.ms)
        .then()
        .fadeIn(duration: 900.ms);
  }
}
