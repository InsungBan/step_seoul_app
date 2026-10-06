import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'hq_palette.dart';
import 'hq_repository.dart';

class HqLineChart extends StatelessWidget {
  const HqLineChart({super.key, required this.values});
  final Map<String, num> values;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    width: double.infinity,
    child: CustomPaint(painter: _LinePainter(values)),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values);
  final Map<String, num> values;
  void label(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = HqPalette.muted,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final plot = Rect.fromLTWH(
      55,
      15,
      math.max(1, size.width - 75),
      size.height - 50,
    );
    final maxValue = math
        .max(1, values.values.fold<num>(0, math.max))
        .toDouble();
    final grid = Paint()..color = HqPalette.line;
    for (var i = 0; i < 4; i++) {
      final y = plot.bottom - plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      label(canvas, hqNumber(maxValue * i / 3), Offset(0, y - 7));
    }
    final entries = values.entries.toList();
    final dates = entries.map((e) => DateTime.parse(e.key)).toList();
    final span = math.max(1, dates.last.difference(dates.first).inDays);
    final points = List.generate(
      entries.length,
      (i) => Offset(
        entries.length == 1
            ? plot.center.dx
            : plot.left +
                  dates[i].difference(dates.first).inDays / span * plot.width,
        plot.bottom - entries[i].value / maxValue * plot.height,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (points.length > 1) {
      final area = Path.from(path)
        ..lineTo(points.last.dx, plot.bottom)
        ..lineTo(points.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HqPalette.purple.withValues(alpha: .18),
              HqPalette.purple.withValues(alpha: .01),
            ],
          ).createShader(plot),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = HqPalette.purple
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = HqPalette.purple);
      if (i == 0 || i == points.length - 1 || points.length <= 7) {
        label(
          canvas,
          '${dates[i].month}/${dates[i].day}',
          Offset(points[i].dx - 14, plot.bottom + 12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class HqBarChart extends StatelessWidget {
  const HqBarChart({super.key, required this.values, this.money = false});
  final Map<String, num> values;
  final bool money;
  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.values.fold<num>(0, math.max));
    return Column(
      children: values.entries
          .take(8)
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 95,
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (e.value / maxValue).clamp(0, 1).toDouble(),
                        minHeight: 15,
                        color: HqPalette.purple.withValues(alpha: .65),
                        backgroundColor: HqPalette.line,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: money ? 105 : 40,
                    child: Text(
                      '${hqNumber(e.value)}${money ? '원' : ''}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class HqDonutChart extends StatelessWidget {
  const HqDonutChart({super.key, required this.values});
  final Map<String, num> values;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 24,
    runSpacing: 20,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 170,
        height: 170,
        child: CustomPaint(
          painter: _DonutPainter(values),
          child: Center(
            child: Text(
              '상품 수\n${hqNumber(values.values.fold<num>(0, (a, b) => a + b))}개',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 14, color: _stockColor(e.key)),
                    const SizedBox(width: 10),
                    Text(
                      '${e.key}  ${e.value}개',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

Color _stockColor(String key) => key == '정상'
    ? HqPalette.green
    : key == '주의'
    ? HqPalette.orange
    : HqPalette.red;

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values);
  final Map<String, num> values;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.values.fold<num>(0, (a, b) => a + b);
    if (total <= 0) return;
    double start = -math.pi / 2;
    final rect = Rect.fromLTWH(15, 15, size.width - 30, size.height - 30);
    for (final e in values.entries) {
      final angle = e.value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        angle,
        false,
        Paint()
          ..color = _stockColor(e.key)
          ..strokeWidth = 25
          ..style = PaintingStyle.stroke,
      );
      start += angle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}
