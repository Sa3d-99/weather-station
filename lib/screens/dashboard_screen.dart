import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';
import '../widgets/hero_panel.dart';
import '../widgets/sensor_card.dart';
import '../widgets/analytics_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _trend(double? cur, double? prev, double thr) {
    if (cur == null || prev == null) return '—';
    if (cur - prev > thr) return '↑';
    if (cur - prev < -thr) return '↓';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        // Use Selector for coarse top-level rebuild only when key fields change
        child: Selector<AppState, _DashData>(
          selector: (_, s) => _DashData(
            live:         s.live,
            prev:         s.prev,
            internet:     s.internet,
            history:      s.history,
            locationName: s.locationName,
            frameCount:   s.frameCount,
            locationLoading: s.locationLoading,
            locationDeniedForever: s.locationDeniedForever,
          ),
          shouldRebuild: (a, b) => a != b,
          builder: (context, data, _) {
            final live = data.live;
            final prev = data.prev;
            final inet = data.internet;

            return RefreshIndicator(
              color: AppTheme.heroAcc,
              backgroundColor: AppTheme.card,
              onRefresh: () => context.read<AppState>().refreshInternet(),
              child: CustomScrollView(
                // RepaintBoundary on the scrollable for performance
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── App bar ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _AppBar(
                      onRefresh: () =>
                          context.read<AppState>().refreshInternet(),
                    ),
                  ),

                  // ── Hero panel ───────────────────────────────
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: HeroPanel(
                        live: live,
                        internet: inet,
                        locationName: data.locationName,
                        isOnline: live.isOnline,
                        frameCount: data.frameCount,
                        locationLoading: data.locationLoading,
                        locationDeniedForever: data.locationDeniedForever,
                      ).animate().fadeIn(duration: 400.ms),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── 4 Sensor cards in 2×2 grid ───────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      delegate: SliverChildListDelegate([
                        RepaintBoundary(
                          child: SensorCard(
                            title: 'TEMP', unit: '°C',
                            value: live.temp, minVal: -10, maxVal: 50,
                            color: AppTheme.colTemp, label: live.tempLabel,
                            trend: _trend(live.temp, prev?.temp, 0.5),
                            compareValue: inet != null
                                ? '${inet.temp.toStringAsFixed(1)}°C'
                                : null,
                          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
                        ),
                        RepaintBoundary(
                          child: SensorCard(
                            title: 'HUM', unit: '%',
                            value: live.hum, minVal: 0, maxVal: 100,
                            color: AppTheme.colHum, label: live.humLabel,
                            trend: _trend(live.hum, prev?.hum, 1),
                            compareValue: inet != null
                                ? '${inet.hum.toStringAsFixed(0)}%'
                                : null,
                          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.15),
                        ),
                        RepaintBoundary(
                          child: SensorCard(
                            title: 'PRES', unit: 'hPa',
                            value: live.pres, minVal: 950, maxVal: 1050,
                            color: AppTheme.colPres, label: live.presLabel,
                            trend: _trend(live.pres, prev?.pres, 0.5),
                            compareValue: inet != null
                                ? '${inet.pressure.toStringAsFixed(0)}hPa'
                                : null,
                          ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.15),
                        ),
                        RepaintBoundary(
                          child: SensorCard(
                            title: 'WIND', unit: 'm/s',
                            value: live.wind, minVal: 0, maxVal: 20,
                            color: AppTheme.colWind, label: live.windLabel,
                            trend: _trend(live.wind, prev?.wind, 0.1),
                            compareValue: inet != null
                                ? '${inet.windSpeed.toStringAsFixed(1)}m/s'
                                : null,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                        ),
                      ]),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── History chart (4-tab boxes) ───────────────
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: HistoryChart(history: data.history)
                          .animate()
                          .fadeIn(delay: 240.ms),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Sensor vs Internet comparison ─────────────
                  SliverToBoxAdapter(
                    child: ComparisonPanel(sensor: live, internet: inet)
                        .animate()
                        .fadeIn(delay: 280.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Weather analytics ─────────────────────────
                  SliverToBoxAdapter(
                    child: WeatherAnalyticsPanel(
                      sensor: live,
                      internet: inet,
                      history: data.history,
                    ).animate().fadeIn(delay: 320.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Simulator / test panel ────────────────────
                  SliverToBoxAdapter(child: _TestPanel()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Data holder for Selector equality check ─────────────────
class _DashData {
  final WeatherData live;
  final WeatherData? prev;
  final InternetWeather? internet;
  final List<WeatherData> history;
  final String locationName;
  final int frameCount;
  final bool locationLoading;
  final bool locationDeniedForever;

  const _DashData({
    required this.live, required this.prev, required this.internet,
    required this.history, required this.locationName,
    required this.frameCount, required this.locationLoading,
    required this.locationDeniedForever,
  });

  @override
  bool operator ==(Object other) =>
      other is _DashData &&
      live.timestamp == other.live.timestamp &&
      history.length == other.history.length &&
      internet?.fetchedAt == other.internet?.fetchedAt &&
      locationName == other.locationName &&
      locationLoading == other.locationLoading;

  @override
  int get hashCode => Object.hash(
      live.timestamp, history.length, internet?.fetchedAt,
      locationName, locationLoading);
}

// ─── App bar ─────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AppBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: const BoxDecoration(
          color: AppTheme.card,
          border: Border(bottom: BorderSide(color: AppTheme.divider))),
      child: Row(children: [
        Text('WX',
            style: GoogleFonts.orbitron(
                color: AppTheme.heroAcc,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('STATION',
              style: GoogleFonts.orbitron(
                  color: AppTheme.heroAcc, fontSize: 9, letterSpacing: 3)),
          Text('ESP32 MONITOR',
              style: GoogleFonts.shareTechMono(
                  color: AppTheme.subtext, fontSize: 8)),
        ]),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.heroAcc, size: 20),
          onPressed: onRefresh,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ─── Test / Simulator panel ──────────────────────────────────
class _TestPanel extends StatefulWidget {
  @override
  State<_TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<_TestPanel> {
  bool _expanded = false;

  static WeatherData _wd(double t, double h, double p, double w) =>
      WeatherData(temp: t, hum: h, pres: p, wind: w, timestamp: DateTime.now());

  static final _presets = [
    ('HOT & HUMID',  _wd(38.5, 85,  1008, 2.1)),
    ('COLD & DRY',   _wd(4.2,  22,  1025, 0.4)),
    ('STORMY',       _wd(16,   95,  978,  14.5)),
    ('MILD',         _wd(22,   55,  1013, 3.2)),
    ('ISMAILIA',     _wd(28.5, 42,  1011, 4.3)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.heroAcc.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  _expanded
                      ? Icons.expand_less
                      : Icons.science_outlined,
                  color: AppTheme.heroAcc, size: 15),
              const SizedBox(width: 6),
              Text('SIMULATOR / TEST DATA',
                  style: GoogleFonts.orbitron(
                      color: AppTheme.heroAcc,
                      fontSize: 9, letterSpacing: 1.5)),
            ]),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) => _btn(context, p.$1, p.$2)).toList(),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _btn(BuildContext ctx, String label, WeatherData d) =>
      GestureDetector(
        onTap: () async {
          await ctx.read<AppState>().pushTestData(d);
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Pushed: $label',
                  style: GoogleFonts.orbitron(
                      color: AppTheme.bg, fontSize: 10)),
              backgroundColor: AppTheme.heroAcc,
              duration: const Duration(seconds: 2),
            ));
          }
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.heroAcc.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: AppTheme.heroAcc.withOpacity(0.4)),
          ),
          child: Text(label,
              style: GoogleFonts.orbitron(
                  color: AppTheme.heroAcc,
                  fontSize: 9, letterSpacing: 0.8)),
        ),
      );
}
