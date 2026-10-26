import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbay_ui/lakbay_ui.dart';

import '../backend/admin_backend.dart';
import '../backend/dataset.dart';
import '../photos/photo_upload_dialog.dart';
import '../state/providers.dart';
import 'collection_specs.dart';
import 'edit_logic.dart';
import 'form_fields.dart';

/// Edits one document of a collection (or creates one when [docId] is null).
///
/// Opened from a report ([reportId]), saving also marks the report approved.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.collection,
    this.docId,
    this.reportId,
  });

  final String collection;
  final String? docId;
  final String? reportId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  Json? _draft;
  Json? _before;
  final _errors = <String, String>{};
  final _source = TextEditingController();
  bool _verified = false;
  bool _saving = false;

  /// True once staff type their own ID; until then it follows the name.
  bool _idEdited = false;
  List<String> _problems = const [];

  CollectionSpec get _spec => specFor(widget.collection)!;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _init(Dataset data) {
    final existing = widget.docId == null
        ? null
        : data.item(widget.collection, widget.docId!);
    _before = existing == null ? null : deepCopy(existing);
    _draft = existing == null ? deepCopy(_spec.newItem) : deepCopy(existing);
    final key = _spec.verificationKey;
    if (key != null) {
      final v = Verification.fromJson(_draft![key] as Json?);
      _source.text = v.source == 'PLACEHOLDER' ? '' : v.source;
    }
    if (widget.collection == 'advisories' && existing == null) {
      _draft!['validFrom'] = nowManilaIso(ref.read(clockProvider)());
    }
  }

  void _changed(Dataset data) {
    if (widget.docId == null && !_idEdited && _spec.hasIdField) {
      final id = suggestId(_spec, _draft!, data);
      if (id != null) _draft!['id'] = id;
    }
    setState(() {});
  }

  Future<void> _save(Dataset data, {Json? override}) async {
    if (_errors.isNotEmpty) {
      setState(() => _problems = ['Fix the highlighted fields first']);
      return;
    }
    final staff = ref.read(currentStaffProvider);
    final now = ref.read(clockProvider)();
    var item = tidyForSave(_spec.fields, deepCopy(override ?? _draft!));
    if (widget.collection == 'advisories') {
      item['publishedAt'] ??= nowManilaIso(now);
    }
    final key = _spec.verificationKey;
    if (key != null) {
      item = stampVerification(
        item,
        key: key,
        before: _before,
        verified: _verified,
        source: _source.text,
        uid: staff.uid,
        today: now,
      );
    }
    if (_verified && _source.text.trim().isEmpty) {
      setState(() => _problems = ['Say where you verified it (source)']);
      return;
    }
    final check = checkEdit(
      spec: _spec,
      data: data,
      existingId: widget.docId,
      draft: item,
    );
    if (!check.ok) {
      setState(() => _problems = friendlyProblems(check.problems, data));
      return;
    }
    if (_before != null &&
        canonicalJson(cleanItem(_before!)) == canonicalJson(check.item)) {
      setState(() => _problems = ['Nothing changed']);
      return;
    }
    await _write(
      AuditedWrite(
        collection: widget.collection,
        docId: check.docId,
        auditId: ref.read(idGeneratorProvider)(),
        before: _before,
        after: check.item,
        reportId: widget.reportId,
      ),
      message: 'Saved',
    );
  }

  Future<void> _delete(Dataset data) async {
    final problems = checkDelete(_spec, data, widget.docId!);
    if (problems.isNotEmpty) {
      setState(
        () => _problems = ['Cannot delete: other data uses it', ...problems],
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this ${_spec.singular}?'),
        content: const Text(
          'Phones remove it at their next sync. The change log keeps a copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDelete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _write(
      AuditedWrite(
        collection: widget.collection,
        docId: widget.docId!,
        auditId: ref.read(idGeneratorProvider)(),
        before: _before,
        after: null,
      ),
      message: 'Deleted',
    );
  }

  Future<void> _write(AuditedWrite write, {required String message}) async {
    setState(() {
      _saving = true;
      _problems = const [];
    });
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final backend = ref.read(backendProvider);
      await backend.save(write);
      if (widget.reportId != null) {
        await backend.reviewReport(
          widget.reportId!,
          status: ReportStatus.approved,
          auditId: write.auditId,
        );
        ref.invalidate(reportsProvider);
      }
      await ref.read(datasetProvider.notifier).reload();
      messenger.showSnackBar(SnackBar(content: Text(message)));
      router.go('/data/${widget.collection}');
    } on Object catch (e) {
      setState(() => _problems = ['Could not save: $e']);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(datasetProvider);
    final data = dataset.value;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_draft == null) _init(data);
    if (widget.docId != null && _before == null) {
      return Center(child: Text('This ${_spec.singular} no longer exists.'));
    }
    final draft = _draft!;
    final theme = Theme.of(context);
    final isAdvisory = widget.collection == 'advisories';

    // Not lazy: forms are short, and every field stays alive while editing.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.docId == null
                ? 'New ${_spec.singular}'
                : 'Edit ${_spec.singular}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _HowToCard(text: _spec.howTo),
          const SizedBox(height: 16),
          if (widget.reportId != null)
            _ReportContext(reportId: widget.reportId!),
          if (isAdvisory) _AdvisoryPreview(draft: draft),
          SpecForm(
            fields: _spec.fields,
            draft: draft,
            data: data,
            errors: _errors,
            isNew: widget.docId == null,
            onChanged: () => _changed(data),
            onIdEdited: () => _idEdited = true,
          ),
          if (_spec.hasPhotos)
            _PhotosSection(draft: draft, onChanged: () => setState(() {})),
          if (_spec.verificationKey != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Did you check this yourself?',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Saving alone does not mark anything as checked. Tick the box only if '
                      'you confirmed these details today: at the port, by phone with the '
                      'company, or from an official notice. Otherwise the app shows them as '
                      '"not verified".',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('verificationSource'),
                      controller: _source,
                      decoration: const InputDecoration(
                        labelText: 'How did you check?',
                        hintText: 'e.g. Called the Odiongan ticket office, 20 Nov 2026',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    CheckboxListTile(
                      key: const Key('verifiedCheckbox'),
                      contentPadding: EdgeInsets.zero,
                      value: _verified,
                      onChanged: (v) => setState(() => _verified = v ?? false),
                      title: const Text('I verified these details today'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_problems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              key: const Key('saveProblems'),
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in _problems)
                      Text(
                        '• $p',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                key: const Key('save'),
                onPressed: _saving ? null : () => _save(data),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  isAdvisory && widget.docId == null ? 'Publish' : 'Save',
                ),
              ),
              if (isAdvisory &&
                  widget.docId != null &&
                  draft['validUntil'] == null)
                OutlinedButton.icon(
                  key: const Key('endAdvisory'),
                  onPressed: _saving
                      ? null
                      : () => _save(
                          data,
                          override: {
                            ...draft,
                            'validUntil': nowManilaIso(
                              ref.read(clockProvider)(),
                            ),
                          },
                        ),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('End now'),
                ),
              if (widget.docId != null)
                OutlinedButton.icon(
                  key: const Key('delete'),
                  onPressed: _saving ? null : () => _delete(data),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              TextButton(
                onPressed: () => context.go('/data/${widget.collection}'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportContext extends ConsumerWidget {
  const _ReportContext({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider(false)).value ?? const [];
    final item = reports.where((r) => r.report.id == reportId).firstOrNull;
    final r = item?.report;
    return Card(
      key: const Key('reportContext'),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traveller report',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (r == null)
              const Text('Loading the report…')
            else ...[
              Text('${r.kind.name} · ${r.targetLabel}'),
              if (r.suggestedValue.isNotEmpty)
                Text('Suggested: ${r.suggestedValue}'),
              if (r.note.isNotEmpty) Text('Note: ${r.note}'),
            ],
            const SizedBox(height: 8),
            const Text(
              'Check the suggestion yourself before changing anything. '
              'Saving marks the report approved.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryPreview extends StatelessWidget {
  const _AdvisoryPreview({required this.draft});

  final Json draft;

  @override
  Widget build(BuildContext context) {
    final colors = AdvisoryColors.of(context);
    final severity = draft['severity'] as String? ?? 'info';
    final title = draft['title'] == null
        ? ''
        : LocalizedText.fromJson(draft['title']).en;
    final tone = switch (severity) {
      'suspended' => colors.suspended,
      'caution' => colors.caution,
      _ => colors.notice,
    };
    final icon = switch (severity) {
      'suspended' => Icons.block,
      'caution' => Icons.warning_amber_rounded,
      _ => Icons.info_outline,
    };
    final label = switch (severity) {
      'suspended' => 'Suspended',
      'caution' => 'Caution',
      _ => 'Notice',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Banner preview (as travellers see it)'),
          const SizedBox(height: 4),
          Container(
            key: const Key('advisoryPreview'),
            width: 420,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tone.background,
              border: Border.all(color: tone.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: tone.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label: $title',
                    style: TextStyle(
                      color: tone.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Guide photos and the layout image, uploaded with permission checks.
/// Photo uploads need Firebase Storage, which needs the Blaze plan. Turn this
/// on after upgrading and deploying `firebase/storage.rules`.
final photoUploadsEnabledProvider = Provider<bool>((ref) => false);

class _HowToCard extends StatelessWidget {
  const _HowToCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('howTo'),
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          Icons.lightbulb_outline,
          color: scheme.onPrimaryContainer,
        ),
        title: Text(
          'How to use this page',
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(text, style: TextStyle(color: scheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.draft, required this.onChanged});

  final Json draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(photoUploadsEnabledProvider);
    final photos = [
      for (final p in (draft['photos'] as List<Object?>? ?? const []))
        if (p is Map<String, Object?>) p,
    ];
    final guideId = draft['id'] as String? ?? 'new';
    final layout = draft['layout'] as Map<String, Object?>?;

    void store() {
      draft['photos'] = photos;
      onChanged();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const Text(
              'Real photos only, taken by you or with permission. Avoid faces and plate numbers.',
            ),
            const SizedBox(height: 12),
            if (photos.isEmpty) const Text('No photos yet.'),
            for (final (i, p) in photos.indexed)
              ListTile(
                key: ValueKey('photo-$i-${p['url']}'),
                contentPadding: EdgeInsets.zero,
                leading: p['url'] is String
                    ? Image.network(
                        p['url']! as String,
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      )
                    : const Icon(Icons.image_outlined),
                title: Text(
                  p['caption'] == null
                      ? '(no caption)'
                      : LocalizedText.fromJson(p['caption']).en,
                ),
                subtitle: Text('Photo by ${p['credit'] ?? '?'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Move up',
                      onPressed: i == 0
                          ? null
                          : () {
                              photos.insert(i - 1, photos.removeAt(i));
                              store();
                            },
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () {
                        photos.removeAt(i);
                        store();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            if (!uploads)
              Padding(
                key: const Key('photosNeedBlaze'),
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Photo uploads are not available yet: they need the Firebase Blaze plan. '
                  'Everything else on this page works.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton.icon(
                  key: const Key('addPhoto'),
                  onPressed: !uploads
                      ? null
                      : () async {
                          final photo = await showPhotoUploadDialog(
                            context,
                            guideId: guideId,
                          );
                          if (photo != null) {
                            photos.add(photo);
                            store();
                          }
                        },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Upload photo'),
                ),
                OutlinedButton.icon(
                  key: const Key('addLayoutImage'),
                  onPressed: !uploads
                      ? null
                      : () async {
                          final image = await showPhotoUploadDialog(
                            context,
                            guideId: guideId,
                            kind: UploadKind.layout,
                          );
                          if (image == null) return;
                          draft['layout'] = {
                            'width': 12,
                            'height': 8,
                            'areas': <Object?>[],
                            ...?layout,
                            'imageUrl': image['url'],
                            'isIllustrative': false,
                            'verification': {
                              'source': 'Layout image by ${image['credit']}',
                              'isPlaceholder': true,
                              'lastVerified': null,
                            },
                          };
                          onChanged();
                        },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    layout?['imageUrl'] == null
                        ? 'Upload layout image'
                        : 'Replace layout image',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Uploads are kept when you save the guide. Removed photos stay in storage; delete them from the Firebase console if needed.',
            ),
          ],
        ),
      ),
    );
  }
}
