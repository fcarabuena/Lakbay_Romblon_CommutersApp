import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../state/providers.dart';
import 'photo_processing.dart';

typedef PickedFile = ({String name, Uint8List bytes});

/// Opens the browser's file picker; overridable in tests.
final filePickerProvider = Provider<Future<PickedFile?> Function()>(
  (ref) => () async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    return (name: file.name, bytes: await file.readAsBytes());
  },
);

/// Shrinks a photo; overridable in tests (decoding is slow there).
final photoPreparerProvider = Provider<PreparedPhoto Function(Uint8List)>(
  (ref) => preparePhoto,
);

/// What to upload: a guide photo (with caption and credit) or a layout image.
enum UploadKind { photo, layout }

/// Asks for a photo and the permissions needed to publish it, then uploads
/// it. Returns the photo entry for the guide (`url`, `storagePath`, caption,
/// credit and the confirmations), or null if cancelled.
Future<Json?> showPhotoUploadDialog(
  BuildContext context, {
  required String guideId,
  UploadKind kind = UploadKind.photo,
}) => showDialog<Json>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _PhotoUploadDialog(guideId: guideId, kind: kind),
);

class _PhotoUploadDialog extends ConsumerStatefulWidget {
  const _PhotoUploadDialog({required this.guideId, required this.kind});

  final String guideId;
  final UploadKind kind;

  @override
  ConsumerState<_PhotoUploadDialog> createState() => _PhotoUploadDialogState();
}

class _PhotoUploadDialogState extends ConsumerState<_PhotoUploadDialog> {
  PickedFile? _file;
  final _captionEn = TextEditingController();
  final _captionFil = TextEditingController();
  final _credit = TextEditingController();
  bool _permission = false;
  bool _noFaces = false;
  bool _busy = false;
  String? _error;

  bool get _isPhoto => widget.kind == UploadKind.photo;

  bool get _ready =>
      _file != null &&
      _permission &&
      _noFaces &&
      _credit.text.trim().isNotEmpty &&
      (!_isPhoto || _captionEn.text.trim().isNotEmpty);

  @override
  void dispose() {
    _captionEn.dispose();
    _captionFil.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(filePickerProvider)();
    if (file != null) setState(() => _file = file);
  }

  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    try {
      final prepared = ref.read(photoPreparerProvider)(_file!.bytes);
      final now = ref.read(clockProvider)().toUtc();
      final path =
          'guides/${widget.guideId}/${_isPhoto ? 'photo' : 'layout'}-${now.millisecondsSinceEpoch}.jpg';
      final url = await ref
          .read(backendProvider)
          .uploadImage(path, prepared.bytes);
      final staff = ref.read(currentStaffProvider);
      navigator.pop(<String, Object?>{
        'url': url,
        'storagePath': path,
        if (_isPhoto)
          'caption': {
            'en': _captionEn.text.trim(),
            if (_captionFil.text.trim().isNotEmpty)
              'fil': _captionFil.text.trim(),
          },
        'credit': _credit.text.trim(),
        'permissionConfirmed': true,
        'noFacesConfirmed': true,
        'uploadedBy': staff.uid,
        'uploadedAt': now.toIso8601String(),
        'width': prepared.width,
        'height': prepared.height,
      });
    } on FormatException {
      setState(
        () => _error =
            'That file is not an image the panel can read. Use a JPEG or PNG.',
      );
    } on PhotoTooLarge {
      setState(
        () => _error = 'The photo is too detailed to fit in 200 KB. Try a smaller or simpler photo.',
      );
    } on Object catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isPhoto ? 'Upload a photo' : 'Upload a layout image'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                key: const Key('pickPhoto'),
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.image_outlined),
                label: Text(_file?.name ?? 'Choose image…'),
              ),
              const SizedBox(height: 4),
              const Text(
                'It will be resized to at most 1280 px and 200 KB, and its location data removed.',
              ),
              if (_isPhoto) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('captionEn'),
                  controller: _captionEn,
                  decoration: const InputDecoration(
                    labelText: 'Caption (English) *',
                    hintText: 'e.g. Ticket windows, left of the entrance',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('captionFil'),
                  controller: _captionFil,
                  decoration: const InputDecoration(
                    labelText: 'Caption (Tagalog, optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                key: const Key('credit'),
                controller: _credit,
                decoration: const InputDecoration(
                  labelText: 'Photo by *',
                  hintText: 'Who took it, as it should be credited',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('confirmPermission'),
                contentPadding: EdgeInsets.zero,
                value: _permission,
                onChanged: (v) => setState(() => _permission = v ?? false),
                title: const Text(
                  'I took this photo or have permission to use it.',
                ),
              ),
              CheckboxListTile(
                key: const Key('confirmNoFaces'),
                contentPadding: EdgeInsets.zero,
                value: _noFaces,
                onChanged: (v) => setState(() => _noFaces = v ?? false),
                title: const Text(
                  'No one can be recognised (faces) and no plate numbers are readable.',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('uploadPhoto'),
          onPressed: _ready && !_busy ? _upload : null,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: const Text('Upload'),
        ),
      ],
    );
  }
}
