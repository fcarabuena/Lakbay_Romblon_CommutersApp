import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakbay_ui/lakbay_ui.dart';

Color _materialColor(WidgetTester tester, Finder button) => tester
    .widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    )
    .color!;

void main() {
  testWidgets('the main action button is island green with white text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LakbayTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              FilledButton(
                key: const Key('main'),
                onPressed: () {},
                child: const Text('Find routes'),
              ),
              OutlinedButton(
                key: const Key('secondary'),
                onPressed: () {},
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      _materialColor(tester, find.byKey(const Key('main'))),
      const Color(0xFF1F7A4D),
    );
    final label = tester.widget<DefaultTextStyle>(
      find
          .descendant(
            of: find.byKey(const Key('main')),
            matching: find.byType(DefaultTextStyle),
          )
          .last,
    );
    expect(label.style.color, Colors.white);
    expect(
      tester.getSize(find.byKey(const Key('main'))).height,
      greaterThanOrEqualTo(48),
    );

    final outlined = tester.widget<OutlinedButton>(
      find.byKey(const Key('secondary')),
    );
    final side =
        outlined.style ??
        Theme.of(tester.element(find.byKey(const Key('secondary'))))
            .outlinedButtonTheme
            .style!;
    expect(side.side!.resolve({})!.color, const Color(0xFF0B5C7A));
  });

  test('the colour scheme uses the exact Tide colours', () {
    final theme = LakbayTheme.light();
    final s = theme.colorScheme;
    expect(s.primary, const Color(0xFF0B5C7A));
    expect(s.primaryContainer, const Color(0xFFE1EFF3));
    expect(s.secondary, const Color(0xFF1F7A4D));
    expect(s.secondaryContainer, const Color(0xFFE3F1E8));
    expect(s.surface, Colors.white);
    expect(s.onSurface, const Color(0xFF10232B));
    expect(s.onSurfaceVariant, const Color(0xFF4F6670));
    expect(s.outline, const Color(0xFF7C9098));
    expect(s.outlineVariant, const Color(0xFFD5E1E4));
    expect(s.error, const Color(0xFFB42318));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF2F7F8));
    expect(theme.brightness, Brightness.light);
  });

  test('text uses the bundled Figtree and never goes below 11', () {
    final text = LakbayTheme.light().textTheme;
    expect(text.bodyLarge!.fontFamily, 'packages/lakbay_ui/Figtree');
    expect(text.titleLarge!.fontSize, 20);
    expect(text.titleLarge!.fontWeight, FontWeight.w700);
    expect(text.bodyMedium!.fontSize, 15);
    expect(text.bodySmall!.fontSize, 13);
    expect(text.labelLarge!.fontWeight, FontWeight.w700);
    for (final style in [
      text.headlineSmall,
      text.titleLarge,
      text.titleMedium,
      text.titleSmall,
      text.bodyLarge,
      text.bodyMedium,
      text.bodySmall,
      text.labelLarge,
      text.labelMedium,
      text.labelSmall,
    ]) {
      expect(style!.fontSize, greaterThanOrEqualTo(11));
    }
  });

  test('advisory colours keep their meanings', () {
    final colors = LakbayTheme.light().extension<AdvisoryColors>()!;
    expect(colors.suspended.background, const Color(0xFFFEF3F2));
    expect(colors.suspended.foreground, const Color(0xFF9A1C12));
    expect(colors.suspended.border, const Color(0xFFF4B4AD));
    expect(colors.caution.background, const Color(0xFFFFF6DB));
    expect(colors.caution.foreground, const Color(0xFF6B4600));
    expect(colors.notice.background, const Color(0xFFE1EFF3));
    expect(colors.notice.foreground, const Color(0xFF0B3F54));
    expect(
      colors.lerp(colors, 0.5).caution.background,
      colors.caution.background,
    );
  });

  test('cards are flat with a hairline border and 12 radius', () {
    final card = LakbayTheme.light().cardTheme;
    expect(card.elevation, 0);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.color, const Color(0xFFD5E1E4));
    expect(shape.borderRadius, const BorderRadius.all(Radius.circular(12)));
  });
}
