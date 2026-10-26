import '../json.dart';
import 'geo.dart';
import 'localized_text.dart';
import 'verification.dart';

/// What an area of a pier or terminal is used for; drives colour and icon.
enum AreaKind {
  entrance,
  ticketing,
  waiting,
  restroom,
  food,
  baggage,
  gate,
  boarding,
  transport,
  security,
  office,
  other,
}

/// A rectangle on a schematic layout, in layout units (not metres).
final class LayoutArea {
  const LayoutArea({
    required this.id,
    required this.kind,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final AreaKind kind;
  final LocalizedText label;
  final double x;
  final double y;
  final double width;
  final double height;

  factory LayoutArea.fromJson(Json json) => LayoutArea(
    id: json.req<String>('id'),
    kind: AreaKind.values.byName(json.opt<String>('kind') ?? 'other'),
    label: LocalizedText.fromJson(json['label']),
    x: json.req<num>('x').toDouble(),
    y: json.req<num>('y').toDouble(),
    width: json.req<num>('w').toDouble(),
    height: json.req<num>('h').toDouble(),
  );
}

/// A simple drawn plan of a pier or terminal that works offline.
///
/// Editors can replace it two ways: edit the [areas] (pure data, editable in
/// the admin panel), or upload a sketch/photo as [imageUrl], which is shown
/// instead of the drawing. See `docs/guide-layout-format.md`.
final class GuideLayout {
  const GuideLayout({
    required this.width,
    required this.height,
    required this.areas,
    required this.verification,
    this.isIllustrative = true,
    this.imageUrl,
    this.imageAsset,
    this.seaSide,
  });

  final double width;
  final double height;
  final List<LayoutArea> areas;

  /// True while the layout is a placeholder drawing, not a surveyed plan.
  final bool isIllustrative;

  /// A replacement image (network, e.g. from the admin panel) or bundled
  /// asset. When set, it is shown instead of the drawn [areas].
  final String? imageUrl;
  final String? imageAsset;

  /// Which edge faces the water ("top", "bottom", "left", "right").
  final String? seaSide;
  final Verification verification;

  bool get hasImage => imageUrl != null || imageAsset != null;

  factory GuideLayout.fromJson(Json json) => GuideLayout(
    width: json.req<num>('width').toDouble(),
    height: json.req<num>('height').toDouble(),
    areas: json.objects('areas').map(LayoutArea.fromJson).toList(),
    isIllustrative: json.opt<bool>('isIllustrative') ?? true,
    imageUrl: json.opt<String>('imageUrl'),
    imageAsset: json.opt<String>('imageAsset'),
    seaSide: json.opt<String>('seaSide'),
    verification: Verification.fromJson(json.opt<Json>('verification')),
  );
}

/// A point on the real map (ticket office, bus bay...).
final class PointOfInterest {
  const PointOfInterest({
    required this.id,
    required this.kind,
    required this.label,
    this.location,
  });

  final String id;
  final AreaKind kind;
  final LocalizedText label;
  final GeoPoint? location;

  factory PointOfInterest.fromJson(Json json) {
    final loc = json.opt<Json>('location');
    return PointOfInterest(
      id: json.req<String>('id'),
      kind: AreaKind.values.byName(json.opt<String>('kind') ?? 'other'),
      label: LocalizedText.fromJson(json['label']),
      location: loc == null ? null : GeoPoint.fromJson(loc),
    );
  }
}

/// A real photo of a pier or terminal, bundled ([asset]) or uploaded through
/// the admin panel ([url]). Uploads record who took it ([credit]); the panel
/// only accepts photos the uploader has permission to use.
final class GuidePhoto {
  const GuidePhoto({this.asset, this.url, this.caption, this.credit});

  final String? asset;
  final String? url;
  final LocalizedText? caption;
  final String? credit;

  factory GuidePhoto.fromJson(Json json) => GuidePhoto(
    asset: json.opt<String>('asset'),
    url: json.opt<String>('url'),
    caption: LocalizedText.maybe(json['caption']),
    credit: json.opt<String>('credit'),
  );
}

/// Everything a traveller should know about one pier or terminal.
final class Guide {
  const Guide({
    required this.id,
    required this.placeId,
    required this.tips,
    required this.verification,
    this.layout,
    this.pointsOfInterest = const [],
    this.photos = const [],
    this.summary,
  });

  final String id;

  /// The port or bus terminal this guide is about.
  final String placeId;
  final LocalizedText? summary;
  final List<LocalizedText> tips;
  final GuideLayout? layout;
  final List<PointOfInterest> pointsOfInterest;
  final List<GuidePhoto> photos;
  final Verification verification;

  factory Guide.fromJson(Json json) {
    final layout = json.opt<Json>('layout');
    return Guide(
      id: json.req<String>('id'),
      placeId: json.req<String>('placeId'),
      summary: LocalizedText.maybe(json['summary']),
      tips: [
        for (final t in json.opt<List<Object?>>('tips') ?? const <Object?>[])
          LocalizedText.fromJson(t),
      ],
      layout: layout == null ? null : GuideLayout.fromJson(layout),
      pointsOfInterest: json
          .objects('pointsOfInterest')
          .map(PointOfInterest.fromJson)
          .toList(),
      photos: json.objects('photos').map(GuidePhoto.fromJson).toList(),
      verification: Verification.fromJson(json.opt<Json>('verification')),
    );
  }
}
