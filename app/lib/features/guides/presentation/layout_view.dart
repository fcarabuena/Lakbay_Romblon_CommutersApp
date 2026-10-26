import 'package:flutter/material.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/ui/formatters.dart';

IconData areaIcon(AreaKind kind) => switch (kind) {
  AreaKind.entrance => Icons.door_front_door_outlined,
  AreaKind.ticketing => Icons.confirmation_number_outlined,
  AreaKind.waiting => Icons.event_seat_outlined,
  AreaKind.restroom => Icons.wc,
  AreaKind.food => Icons.restaurant,
  AreaKind.baggage => Icons.luggage_outlined,
  AreaKind.gate => Icons.meeting_room_outlined,
  AreaKind.boarding => Icons.directions_boat_outlined,
  AreaKind.transport => Icons.directions_bus_outlined,
  AreaKind.security => Icons.shield_outlined,
  AreaKind.office => Icons.payments_outlined,
  AreaKind.other => Icons.place_outlined,
};

Color areaColor(ColorScheme scheme, AreaKind kind) => switch (kind) {
  AreaKind.boarding || AreaKind.gate => scheme.primaryContainer,
  AreaKind.ticketing || AreaKind.office => scheme.tertiaryContainer,
  AreaKind.waiting || AreaKind.food => scheme.secondaryContainer,
  AreaKind.transport => scheme.surfaceContainerHighest,
  _ => scheme.surfaceContainerHigh,
};

/// Draws a schematic pier or terminal layout, scaled to the available width.
///
/// The drawing is decorative for screen readers; [LayoutAreaList] below it
/// carries the same information as text.
class LayoutView extends StatelessWidget {
  const LayoutView({super.key, required this.layout});

  final GuideLayout layout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = context.languageCode;
    final hasSea = layout.seaSide == 'top';
    final drawing = AspectRatio(
      aspectRatio: layout.width / layout.height,
      child: CustomPaint(
        painter: _LayoutPainter(
          layout: layout,
          scheme: scheme,
          labelStyle: Theme.of(context).textTheme.bodySmall!
              .copyWith(fontWeight: FontWeight.w600),
          languageCode: lang,
        ),
      ),
    );

    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSea)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: scheme.primary,
              child: Text(
                '≈≈  ${context.l10n.seaSide}  ≈≈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline),
            ),
            child: drawing,
          ),
        ],
      ),
    );
  }
}

class _LayoutPainter extends CustomPainter {
  _LayoutPainter({
    required this.layout,
    required this.scheme,
    required this.labelStyle,
    required this.languageCode,
  });

  final GuideLayout layout;
  final ColorScheme scheme;
  final TextStyle labelStyle;
  final String languageCode;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / layout.width;
    final sy = size.height / layout.height;
    final fill = Paint();
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = scheme.outline;

    for (final area in layout.areas) {
      final rect = Rect.fromLTWH(
        area.x * sx,
        area.y * sy,
        area.width * sx,
        area.height * sy,
      ).deflate(1.5);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas
        ..drawRRect(rrect, fill..color = areaColor(scheme, area.kind))
        ..drawRRect(rrect, border);

      // Shrink the label until it fits; skip it if the box is tiny.
      for (
        var fontSize = labelStyle.fontSize ?? 14;
        fontSize >= 9;
        fontSize -= 1
      ) {
        final painter = TextPainter(
          text: TextSpan(
            text: area.label.resolve(languageCode),
            style: labelStyle.copyWith(
              fontSize: fontSize,
              color: scheme.onSurface,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 3,
          ellipsis: '…',
        )..layout(maxWidth: rect.width - 6);
        if (painter.height <= rect.height - 4 || fontSize <= 9) {
          if (painter.height <= rect.height) {
            painter.paint(
              canvas,
              Offset(
                rect.center.dx - painter.width / 2,
                rect.center.dy - painter.height / 2,
              ),
            );
          }
          break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LayoutPainter old) =>
      old.layout != layout ||
      old.scheme != scheme ||
      old.languageCode != languageCode;
}

/// The layout areas as a readable, accessible list.
class LayoutAreaList extends StatelessWidget {
  const LayoutAreaList({super.key, required this.layout});

  final GuideLayout layout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = context.languageCode;
    return Column(
      children: [
        for (final area in layout.areas)
          ListTile(
            key: Key('area-${area.id}'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: areaColor(scheme, area.kind),
              foregroundColor: scheme.onSurface,
              child: Icon(areaIcon(area.kind)),
            ),
            title: Text(area.label.resolve(lang)),
          ),
      ],
    );
  }
}
