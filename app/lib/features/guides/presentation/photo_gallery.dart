import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';

/// Keeps uploaded photos on the phone after they are first shown, and can
/// download a guide's photos ahead of time.
abstract interface class PhotoCache {
  Future<bool> isSaved(String url);
  Future<void> save(String url);
}

class CacheManagerPhotoCache implements PhotoCache {
  const CacheManagerPhotoCache();

  @override
  Future<bool> isSaved(String url) async =>
      await DefaultCacheManager().getFileFromCache(url) != null;

  @override
  Future<void> save(String url) => DefaultCacheManager().downloadFile(url);
}

final photoCacheProvider = Provider<PhotoCache>(
  (ref) => const CacheManagerPhotoCache(),
);

/// Whether the phone is on mobile data (to warn before downloading photos).
final onMobileDataProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final types = await Connectivity().checkConnectivity();
    return types.contains(ConnectivityResult.mobile) &&
        !types.contains(ConnectivityResult.wifi);
  },
);

/// Whether network images load. Off in widget tests (no internet there).
final networkImagesEnabledProvider = Provider<bool>((ref) => true);

/// A bundled or uploaded image with a placeholder while loading and a
/// message when it cannot be shown (usually offline before it was saved).
class GuideImage extends ConsumerWidget {
  const GuideImage({
    super.key,
    this.asset,
    this.url,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? asset;
  final String? url;
  final BoxFit fit;

  /// Shown instead of the "not available" message when loading fails.
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Widget message(IconData icon, String text) =>
        fallback ??
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        );

    if (asset != null) {
      return Image.asset(
        asset!,
        fit: fit,
        errorBuilder: (_, _, _) =>
            message(Icons.broken_image_outlined, l10n.photoUnavailable),
      );
    }
    if (url == null || !ref.watch(networkImagesEnabledProvider)) {
      return message(Icons.photo_outlined, l10n.photoLoading);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, _) => message(Icons.photo_outlined, l10n.photoLoading),
      errorWidget: (_, _, _) =>
          message(Icons.cloud_off_outlined, l10n.photoUnavailable),
    );
  }
}

/// The photos section of a guide page.
class GuidePhotoGallery extends ConsumerStatefulWidget {
  const GuidePhotoGallery({super.key, required this.guide});

  final Guide guide;

  @override
  ConsumerState<GuidePhotoGallery> createState() => _GuidePhotoGalleryState();
}

class _GuidePhotoGalleryState extends ConsumerState<GuidePhotoGallery> {
  bool _saving = false;
  bool? _allSaved;

  List<String> get _urls => [for (final p in widget.guide.photos) ?p.url];

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    if (_urls.isEmpty) return;
    final cache = ref.read(photoCacheProvider);
    var all = true;
    for (final url in _urls) {
      if (!await cache.isSaved(url)) {
        all = false;
        break;
      }
    }
    if (mounted) setState(() => _allSaved = all);
  }

  Future<void> _saveAll() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (await ref.read(onMobileDataProvider)()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.photosMobileDataTitle),
          content: Text(l10n.photosMobileDataBody(_urls.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('confirmMobileData'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.photosDownload),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    final cache = ref.read(photoCacheProvider);
    var failed = false;
    for (final url in _urls) {
      try {
        await cache.save(url);
      } on Object {
        failed = true;
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _allSaved = !failed;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed ? l10n.photosSaveFailed : l10n.photosSaved),
      ),
    );
  }

  void _open(GuidePhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhotoViewerScreen(photo: photo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = context.languageCode;
    final photos = widget.guide.photos;
    final theme = Theme.of(context);

    if (photos.isEmpty) {
      return Notice(l10n.noPhotos, icon: Icons.photo_outlined);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, photo) in photos.indexed) ...[
          Semantics(
            button: true,
            label: photo.caption?.resolve(lang) ?? l10n.photoNumber(i + 1),
            child: InkWell(
              key: Key('photo-$i'),
              onTap: () => _open(photo),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: GuideImage(asset: photo.asset, url: photo.url),
                ),
              ),
            ),
          ),
          if (photo.caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                photo.caption!.resolve(lang),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          if (photo.credit != null)
            Text(
              l10n.photoCredit(photo.credit!),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
        ],
        if (_urls.isNotEmpty)
          _allSaved == true
              ? Notice(l10n.photosSaved, tone: NoticeTone.success)
              : OutlinedButton.icon(
                  key: const Key('savePhotos'),
                  onPressed: _saving ? null : _saveAll,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_for_offline_outlined),
                  label: Text(l10n.photosSaveOffline),
                ),
      ],
    );
  }
}

/// A photo full screen, with pinch to zoom.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.photo});

  final GuidePhoto photo;

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption?.resolve(context.languageCode);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.inverseSurface,
      appBar: AppBar(
        backgroundColor: scheme.inverseSurface,
        foregroundColor: scheme.onInverseSurface,
        title: caption == null ? null : Text(caption),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: GuideImage(
            asset: photo.asset,
            url: photo.url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
