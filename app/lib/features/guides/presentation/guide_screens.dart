import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import 'guide_map.dart';
import 'layout_view.dart';
import 'photo_gallery.dart';
import '../../reports/presentation/report_screens.dart';

/// Shows what went wrong (or what is happening) with "Use my location".
class LocationStatus extends ConsumerWidget {
  const LocationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (ref.watch(userLocationProvider)) {
      AsyncData(value: LocationDenied()) => Notice(
        l10n.locationDenied,
        tone: NoticeTone.warning,
      ),
      AsyncData(value: LocationServiceOff()) => Notice(
        l10n.locationOff,
        tone: NoticeTone.warning,
      ),
      AsyncData(value: LocationFailed()) ||
      AsyncError() => Notice(l10n.locationError, tone: NoticeTone.warning),
      AsyncData(value: LocationFound()) => Notice(
        l10n.locationPrivacy,
        icon: Icons.lock_outline,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Piers and bus terminals that have a guide, nearest first when the
/// traveller has shared their location.
class GuideListScreen extends ConsumerWidget {
  const GuideListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final location = ref.watch(userLocationProvider);
    final here = foundLocation(location);

    List<(Place, double?)> sorted(Iterable<Place> places) => here == null
        ? [for (final p in places) (p, null)]
        : sortByDistance(places, here, (p) => p.location);

    final guided = {for (final g in data.guides) g.placeId};
    final ports = sorted(data.ports.where((p) => guided.contains(p.id)));
    final terminals = sorted(
      data.busTerminals.where((t) => guided.contains(t.id)),
    );
    final nearestId = here == null
        ? null
        : sorted([...ports.map((e) => e.$1), ...terminals.map((e) => e.$1)])
              .firstOrNull
              ?.$1
              .id;

    Widget section(String title, List<(Place, double?)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final (place, km) in items)
          Card(
            child: ListTile(
              key: Key('guide-${place.id}'),
              leading: Icon(
                place.kind == PlaceKind.port
                    ? Icons.anchor
                    : Icons.directions_bus_filled,
              ),
              title: Text(place.name),
              subtitle: km == null
                  ? null
                  : Text(l10n.distanceKm(km.toStringAsFixed(km < 10 ? 1 : 0))),
              trailing: place.id == nearestId
                  ? Chip(label: Text(l10n.nearestBadge))
                  : const Icon(Icons.chevron_right),
              onTap: () => context.push('/guide/${place.id}'),
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            key: const Key('useMyLocation'),
            onPressed: location is AsyncLoading
                ? null
                : () => ref.read(userLocationProvider.notifier).request(),
            icon: const Icon(Icons.my_location),
            label: Text(
              location is AsyncLoading ? l10n.locating : l10n.useMyLocation,
            ),
          ),
          const SizedBox(height: 8),
          const LocationStatus(),
          section(l10n.guidePorts, ports),
          section(l10n.guideTerminals, terminals),
        ],
      ),
    );
  }
}

class GuideDetailScreen extends ConsumerWidget {
  const GuideDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final place = data.place(placeId);
    final guide = data.guideFor(placeId);
    if (place == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noGuide)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(place.name),
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.map_outlined), text: l10n.tabLayout),
              Tab(icon: const Icon(Icons.public), text: l10n.tabMap),
              Tab(
                icon: const Icon(Icons.lightbulb_outline),
                text: l10n.tabTips,
              ),
            ],
          ),
        ),
        body: TabBarView(
          // Swiping would fight with panning the map.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _LayoutTab(guide: guide),
            GuideMap(place: place, guide: guide),
            _TipsTab(guide: guide, placeName: place.name),
          ],
        ),
      ),
    );
  }
}

class _LayoutTab extends StatelessWidget {
  const _LayoutTab({required this.guide});

  final Guide? guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final layout = guide?.layout;
    if (layout == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Notice(l10n.noGuide),
      );
    }

    final drawn = LayoutView(layout: layout);
    final Widget picture = switch (layout) {
      GuideLayout(imageAsset: final String asset) => GuideImage(
        asset: asset,
        fit: BoxFit.contain,
        fallback: drawn,
      ),
      GuideLayout(imageUrl: final String url) => GuideImage(
        url: url,
        fit: BoxFit.contain,
        fallback: drawn,
      ),
      _ => drawn,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (guide?.summary != null) ...[
          Text(
            guide!.summary!.resolve(context.languageCode),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
        ],
        if (layout.isIllustrative) ...[
          Notice(
            l10n.layoutIllustrative,
            tone: NoticeTone.warning,
            key: const Key('illustrativeNotice'),
          ),
          const SizedBox(height: 12),
        ],
        picture,
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: VerifiedBadge(layout.verification),
        ),
        if (layout.areas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.layoutAreas,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          LayoutAreaList(layout: layout),
        ],
      ],
    );
  }
}

class _TipsTab extends StatelessWidget {
  const _TipsTab({required this.guide, required this.placeName});

  final Guide? guide;
  final String placeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.languageCode;
    final g = guide;
    if (g == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Notice(l10n.noGuide),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final tip in g.tips)
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(tip.resolve(lang)),
            ),
          ),
        const SizedBox(height: 16),
        Text(l10n.photosTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GuidePhotoGallery(guide: g),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: VerifiedBadge(g.verification),
        ),
        ReportButton(collection: 'guides', id: g.id, label: placeName),
      ],
    );
  }
}
