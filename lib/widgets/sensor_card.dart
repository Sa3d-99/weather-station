import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String unit;
  final double value;
  final double minVal;
  final double maxVal;
  final Color color;
  final String label;
  final String trend;
  final String? compareValue; // internet value

  const SensorCard({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    required this.minVal,
    required this.maxVal,
    required this.color,
    required this.label,
    required this.trend,
    this.compareValue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 18,
              spreadRadius: 1)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Header row: title + trend ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: GoogleFonts.orbitron(
                        color: color,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                Text(trend,
                    style: GoogleFonts.shareTechMono(
                        color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),

            // ── Arc gauge ─────────────────────────────────────
            Expanded(
              child: CustomPaint(
                painter: _ArcPainter(pct: pct, color: color),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    // Value animates when it changes
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        '${value.toStringAsFixed(1)}$unit',
                        key: ValueKey(value.toStringAsFixed(1)),
                        style: GoogleFonts.orbitron(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Label ──────────────────────────────────────────
            Text(label,
                style: GoogleFonts.orbitron(
                    color: color.withOpacity(0.65),
                    fontSize: 8,
                    letterSpacing: 1.2)),

            // ── Firebase / Internet compare badge ─────────────
            if (compareValue != null) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.internet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                  border:
                      Border.all(color: AppTheme.internet.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌐 ',
                        style: TextStyle(fontSize: 8)),
                    Text(compareValue!,
                        style: GoogleFonts.shareTechMono(
                            color: AppTheme.internet, fontSize: 9)),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Arc gauge painter ────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double pct;
  final Color color;
  _ArcPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 150.0 * pi / 180;
    const sweep = 240.0 * pi / 180;
    final cx = size.width / 2;
    final cy = size.height / 2 + 6;
    final r = min(size.width, size.height) * 0.38;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track (background arc)
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = AppTheme.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    if (pct > 0.02) {
      // Glow
      canvas.drawArc(
        rect,
        startAngle,
        sweep * pct,
        false,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Fill
      canvas.drawArc(
        rect,
        startAngle,
        sweep * pct,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      // Needle dot
      final na = startAngle + sweep * pct;
      canvas.drawCircle(
          Offset(cx + r * cos(na), cy + r * sin(na)), 5,
          Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset(cx + r * cos(na), cy + r * sin(na)), 3,
          Paint()..color = color);
    }

    // Center dots
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = color);
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = Colors.white);

    // Ticks
    final tickP = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 1.2;
    for (int i = 0; i <= 10; i++) {
      final a = startAngle + sweep * i / 10;
      final inner = r - (i % 2 == 0 ? 9 : 5);
      canvas.drawLine(
        Offset(cx + inner * cos(a), cy + inner * sin(a)),
        Offset(cx + (r - 1) * cos(a), cy + (r - 1) * sin(a)),
        tickP,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.pct != pct || o.color != color;
}
