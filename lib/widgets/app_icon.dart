import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Ledger outline icon set: 24px grid, round caps/joins, stroke paths
/// lifted verbatim from the design system's Foundations page so the app
/// matches the mockups pixel-for-pixel instead of substituting Material
/// icons that don't exist in the source library.
enum AppIconGlyph {
  dashboard,
  khata,
  item,
  customers,
  settings,
  add,
  search,
  expand,
  back,
  readonly,
  selected,
  close,
  error,
  success,
}

const Map<AppIconGlyph, String> _paths = {
  AppIconGlyph.dashboard:
      '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
  AppIconGlyph.khata:
      '<path d="M5 4.5A1.5 1.5 0 0 1 6.5 3H19v14H6.5A1.5 1.5 0 0 0 5 18.5z"/><path d="M5 18.5A1.5 1.5 0 0 0 6.5 20H19"/><path d="M9 7h6M9 10.5h4"/>',
  AppIconGlyph.item:
      '<path d="M21 8 12 3 3 8v8l9 5 9-5z"/><path d="m3 8 9 5 9-5M12 13v8"/>',
  AppIconGlyph.customers:
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14.5a6.5 6.5 0 0 1 3.5 5.5"/>',
  AppIconGlyph.settings:
      '<path d="M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0"/><circle cx="16" cy="6" r="2"/><circle cx="10" cy="12" r="2"/><circle cx="18" cy="18" r="2"/>',
  AppIconGlyph.add: '<path d="M12 5v14M5 12h14"/>',
  AppIconGlyph.search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  AppIconGlyph.expand: '<path d="m6 9 6 6 6-6"/>',
  AppIconGlyph.back: '<path d="M15 18l-6-6 6-6"/>',
  AppIconGlyph.readonly: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
  AppIconGlyph.selected: '<path d="m5 12 5 5 9-10"/>',
  AppIconGlyph.close: '<path d="M6 6l12 12M18 6 6 18"/>',
  AppIconGlyph.error: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5M12 16h.01"/>',
  AppIconGlyph.success: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
};

class AppIcon extends StatelessWidget {
  final AppIconGlyph glyph;
  final double size;
  final Color color;
  final double strokeWidth;

  const AppIcon(
    this.glyph, {
    super.key,
    this.size = 22,
    required this.color,
    this.strokeWidth = 1.9,
  });

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.toARGB32().toRadixString(16).substring(2)}';
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">${_paths[glyph]}</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}
