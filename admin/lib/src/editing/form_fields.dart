import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lakbay_core/lakbay_core.dart';
import 'package:lakbay_ui/lakbay_ui.dart';
import 'package:latlong2/latlong.dart';

import '../backend/dataset.dart';
import 'collection_specs.dart';
import 'edit_logic.dart';
import 'field_specs.dart';
import 'map_picker.dart';

/// Renders [fields] as friendly inputs that edit [draft] in place.
///
/// Inputs that cannot be read yet (e.g. "abc" for a fare) record a message in
/// [errors] under their path and keep the old value; the editor will not save
/// while [errors] is non-empty. Fields marked `advanced` go into a closed
/// "Advanced (for technical staff)" section.
class SpecForm extends StatelessWidget {
  const SpecForm({
    super.key,
    required this.fields,
    required this.draft,
    required this.data,
    required this.errors,
    required this.onChanged,
    this.isNew = false,
    this.path = '',
    this.index,
    this.count,
    this.onIdEdited,
  });

  final List<FieldSpec> fields;
  final Json draft;
  final Dataset data;
  final Map<String, String> errors;
  final VoidCallback onChanged;
  final bool isNew;
  final String path;

  /// Position within a repeated group (for show/hide rules).
  final int? index;
  final int? count;

  /// Called when staff type their own ID (so it is no longer automatic).
  final VoidCallback? onIdEdited;

  FieldContext get _context => FieldContext(draft, index: index, count: count);

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final f in fields)
        if (f.visibleWhen?.call(_context) ?? true) f,
    ];
    final main = visible.where((f) => !f.advanced).toList();
    final advanced = visible.where((f) => f.advanced).toList();
    Widget item(FieldSpec f) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _field(context, f),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in main) item(f),
        if (advanced.isNotEmpty)
          Card(
            key: ValueKey('advanced-$path'),
            margin: const EdgeInsets.only(bottom: 20),
            child: ExpansionTile(
              leading: const Icon(Icons.tune),
              title: const Text('Advanced (for technical staff)'),
              subtitle: const Text('You do not normally need to change these.'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [for (final f in advanced) item(f)],
            ),
          ),
      ],
    );
  }

  String _path(FieldSpec f) => path.isEmpty ? f.key : '$path.${f.key}';

  String _label(FieldSpec f) => f.required ? '${f.label} *' : f.label;

  void _set(FieldSpec f, Object? value) {
    if (value == null) {
      draft.remove(f.key);
    } else {
      draft[f.key] = value;
    }
    errors.remove(_path(f));
    onChanged();
  }

  void _error(FieldSpec f, String message) {
    errors[_path(f)] = message;
    onChanged();
  }

  InputDecoration _decoration(
    FieldSpec f, {
    String? hint,
    String? prefix,
    String? suffix,
  }) => InputDecoration(
    labelText: _label(f),
    helperText: f.helpLine,
    helperMaxLines: 3,
    hintText: hint,
    prefixText: prefix,
    suffixText: suffix,
    errorText: errors[_path(f)],
    errorMaxLines: 3,
    border: const OutlineInputBorder(),
  );

  Widget _text(
    FieldSpec f, {
    required String initial,
    required void Function(String text) onText,
    bool multiline = false,
    String? prefix,
    String? suffix,
    TextInputType? keyboard,
  }) => TextFormField(
    key: ValueKey('field-${_path(f)}'),
    initialValue: initial,
    minLines: multiline ? 3 : 1,
    maxLines: multiline ? 8 : 1,
    keyboardType: keyboard,
    decoration: _decoration(f, prefix: prefix, suffix: suffix),
    onChanged: onText,
  );

  /// A labelled box around controls that are not a single text field.
  Widget _box(FieldSpec f, Widget child) => InputDecorator(
    key: ValueKey('box-${_path(f)}'),
    decoration: _decoration(f)
        .copyWith(contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12)),
    child: child,
  );

  Widget _field(BuildContext context, FieldSpec f) {
    final value = draft[f.key];
    return switch (f) {
      IdSpec() => _SyncedTextField(
        key: ValueKey('field-${_path(f)}'),
        value: value as String? ?? '',
        enabled: isNew,
        decoration: _decoration(f).copyWith(
          helperText: isNew
              ? f.helpLine
              : 'The ID cannot be changed after saving.',
        ),
        onChanged: (t) {
          onIdEdited?.call();
          _set(f, t.trim());
        },
      ),
      TextSpec(:final multiline) => _text(
        f,
        initial: value as String? ?? '',
        multiline: multiline,
        onText: (t) => _set(f, t.trim().isEmpty ? null : t),
      ),
      IntSpec(:final min, :final minutes) => _text(
        f,
        initial: value == null ? '' : '$value',
        keyboard: TextInputType.number,
        suffix: minutes && value is int && value >= 60
            ? '= ${hoursAndMinutes(value)}'
            : null,
        onText: (t) {
          if (t.trim().isEmpty) return _set(f, null);
          final n = int.tryParse(t.trim());
          n == null || n < min
              ? _error(
                  f,
                  'Enter a whole number${min > 0 ? ' of at least $min' : ''}, e.g. ${f.example ?? 30}',
                )
              : _set(f, n);
        },
      ),
      PesoSpec() => _text(
        f,
        initial: value == null ? '' : '$value',
        prefix: '₱ ',
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        onText: (t) {
          if (t.trim().isEmpty) return _set(f, null);
          final n = parsePeso(t);
          n == null
              ? _error(f, 'Enter pesos only, e.g. ${f.example ?? 650}')
              : _set(f, n);
        },
      ),
      PesoTableSpec(:final rows) => _pesoTable(f, rows, value),
      RangeSpec() => _RangeInput(
        key: ValueKey('field-${_path(f)}'),
        spec: f,
        value: value,
        label: _label(f),
        help: f.helpLine,
        error: errors[_path(f)],
        onValue: (v) => _set(f, v),
        onError: (m) => _error(f, m),
      ),
      ClockSpec() => _box(
        f,
        Row(
          children: [
            OutlinedButton.icon(
              key: ValueKey('clock-${_path(f)}'),
              icon: const Icon(Icons.schedule),
              label: Text(value is String ? clock12(value) : 'Choose time'),
              onPressed: () async {
                final initial =
                    _timeOf(value as String?) ??
                    const TimeOfDay(hour: 8, minute: 0);
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) _set(f, _hhmm(picked));
              },
            ),
            if (value != null && !f.required)
              TextButton(
                onPressed: () => _set(f, null),
                child: const Text('Clear'),
              ),
          ],
        ),
      ),
      DateTimeSpec(:final openEndedLabel) => _dateTime(
        context,
        f,
        value as String?,
        openEndedLabel,
      ),
      BoolSpec(:final defaultValue) => SwitchListTile(
        key: ValueKey('field-${_path(f)}'),
        contentPadding: EdgeInsets.zero,
        title: Text(f.label),
        subtitle: f.helpLine == null ? null : Text(f.helpLine!),
        value: value as bool? ?? defaultValue,
        onChanged: (v) => _set(f, v),
      ),
      ChoiceSpec() => _choice(context, f, value ?? f.defaultValue),
      RefSpec() => _ref(f, value),
      MultiRefSpec(:final target) => _multiRef(f, target, value),
      LocalizedSpec(:final multiline) => _localized(
        f,
        value,
        multiline: multiline,
      ),
      LocalizedListSpec() => _localizedList(f, value),
      CheckboxListSpec(:final choices) => _checkboxes(f, choices, value),
      PhoneListSpec() => _phones(f, value),
      DaysSpec() => _days(f, value),
      GeoSpec(:final townKey) => _geo(context, f, value, townKey),
      ObjectListSpec() => _objectList(context, f, value),
      JsonSpec(:final emptyValue) => _text(
        f,
        initial: value == null
            ? ''
            : const JsonEncoder.withIndent('  ').convert(value),
        multiline: true,
        onText: (t) {
          if (t.trim().isEmpty) return _set(f, emptyValue);
          try {
            _set(f, jsonDecode(t));
          } on FormatException catch (e) {
            _error(f, 'Not valid JSON: ${e.message}');
          }
        },
      ),
    };
  }

  Widget _pesoTable(FieldSpec f, List<Choice> rows, Object? value) {
    final table = value is Map<String, Object?>
        ? {...value}
        : <String, Object?>{};
    return _box(
      f,
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final row in rows)
            SizedBox(
              width: 220,
              child: TextFormField(
                key: ValueKey('field-${_path(f)}-${row.value}'),
                initialValue: table[row.value] == null
                    ? ''
                    : '${table[row.value]}',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: row.label,
                  prefixText: '₱ ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (t) {
                  final key = row.value as String;
                  if (t.trim().isEmpty) {
                    table.remove(key);
                  } else {
                    final n = parsePeso(t);
                    if (n == null) {
                      return _error(
                        f,
                        '${row.label}: enter pesos only, e.g. 960',
                      );
                    }
                    table[key] = n;
                  }
                  _set(f, table.isEmpty ? null : {...table});
                },
              ),
            ),
        ],
      ),
    );
  }

  static TimeOfDay? _timeOf(String? hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm ?? '');
    return m == null
        ? null
        : TimeOfDay(
            hour: int.parse(m.group(1)!),
            minute: int.parse(m.group(2)!),
          );
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _dateTime(
    BuildContext context,
    FieldSpec f,
    String? value,
    String? openEndedLabel,
  ) {
    final manila = value == null ? null : isoToManilaInput(value);
    final date = manila?.substring(0, 10);
    final time = manila?.substring(11);
    void store(String day, String hhmm) =>
        _set(f, manilaInputToIso('$day $hhmm'));
    String today() =>
        isoToManilaInput(DateTime.now().toUtc().toIso8601String());

    return _box(
      f,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (openEndedLabel != null)
            SwitchListTile(
              key: ValueKey('openEnded-${_path(f)}'),
              contentPadding: EdgeInsets.zero,
              title: Text(openEndedLabel),
              value: value == null,
              onChanged: (open) {
                if (open) return _set(f, null);
                final now = today();
                store(now.substring(0, 10), now.substring(11));
              },
            ),
          if (value != null || openEndedLabel == null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('date-${_path(f)}'),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(date == null ? 'Choose date' : _prettyDate(date)),
                  onPressed: () async {
                    final initial = DateTime.parse(
                      date ?? today().substring(0, 10),
                    );
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    final day =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    store(day, time ?? '08:00');
                  },
                ),
                OutlinedButton.icon(
                  key: ValueKey('time-${_path(f)}'),
                  icon: const Icon(Icons.schedule),
                  label: Text(time == null ? 'Choose time' : clock12(time)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          _timeOf(time) ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) {
                      store(date ?? today().substring(0, 10), _hhmm(picked));
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _prettyDate(String ymd) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = DateTime.parse(ymd);
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _choice(BuildContext context, ChoiceSpec f, Object? value) {
    final choices = [
      ...f.choices,
      // A value in the data that is not in the list still shows, unchanged.
      if (value != null && !f.choices.any((c) => c.value == value))
        Choice(value, '$value'),
    ];
    switch (f.style) {
      case ChoiceStyle.dropdown:
        final selected = choices.indexWhere((c) => c.value == value);
        return DropdownButtonFormField<int>(
          key: ValueKey('field-${_path(f)}'),
          initialValue: selected < 0 ? null : selected,
          isExpanded: true,
          decoration: _decoration(f),
          items: [
            for (final (i, c) in choices.indexed)
              DropdownMenuItem(value: i, child: Text(c.label)),
          ],
          onChanged: (i) => _set(f, i == null ? null : choices[i].value),
        );
      case ChoiceStyle.radio:
        return _box(
          f,
          RadioGroup<int>(
            groupValue: choices.indexWhere((c) => c.value == value),
            onChanged: (i) => _set(f, i == null ? null : choices[i].value),
            child: Column(
              children: [
                for (final (i, c) in choices.indexed)
                  RadioListTile<int>(
                    key: ValueKey('choice-${_path(f)}-${c.value}'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: i,
                    title: Text(c.label),
                  ),
              ],
            ),
          ),
        );
      case ChoiceStyle.cards:
        final scheme = Theme.of(context).colorScheme;
        final advisory = AdvisoryColors.of(context);
        AdvisoryTone? toneOf(Choice c) => switch (c.tone) {
          'suspended' => advisory.suspended,
          'caution' => advisory.caution,
          'notice' => advisory.notice,
          _ => null,
        };
        return _box(
          f,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in choices)
                SizedBox(
                  width: 220,
                  child: Card(
                    key: ValueKey('choice-${_path(f)}-${c.value}'),
                    margin: EdgeInsets.zero,
                    color: toneOf(c)?.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: c.value == value
                            ? (toneOf(c)?.foreground ?? scheme.primary)
                            : (toneOf(c)?.border ?? scheme.outlineVariant),
                        width: c.value == value ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _set(f, c.value),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  c.value == value
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color:
                                      toneOf(c)?.foreground ?? scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (c.description != null) ...[
                              const SizedBox(height: 4),
                              Text(c.description!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }

  List<(String, String)> _refOptions(RefSpec f) {
    List<(String, String)> of(String c, String Function(Json) label) => [
      for (final MapEntry(:key, :value) in data.rows[c]!.entries)
        (key, label(value)),
    ];
    String name(Json i) => '${i['name']}';
    final all = switch (f.target) {
      RefTarget.places => [
        ...of('municipalities', (i) => '${i['name']} (town)'),
        ...of('ports', (i) => '${i['name']} (port)'),
        ...of('bus_terminals', (i) => '${i['name']} (bus terminal)'),
        ...of('hubs', (i) => '${i['name']} (Manila hub)'),
      ],
      RefTarget.ports => of('ports', name),
      RefTarget.voyages => of('voyages', (i) => voyageLabel(i, data)),
      RefTarget.shippingLines => of('shipping_lines', name),
      RefTarget.busOperators => of('bus_operators', name),
      RefTarget.municipalities => of('municipalities', name),
    };
    final only = f.only?.call(draft, data);
    final options = only == null
        ? (all..sort((a, b) => a.$2.compareTo(b.$2)))
        : [
            // Keep the given order (e.g. a voyage's stops from first to last).
            for (final id in only) ...all.where((o) => o.$1 == id),
          ];
    return options;
  }

  Widget _ref(RefSpec f, Object? value) {
    final options = _refOptions(f);
    final known = options.any((o) => o.$1 == value);
    if (options.length > 12) {
      return LayoutBuilder(
        builder: (context, constraints) => DropdownMenu<String>(
          key: ValueKey('field-${_path(f)}-${known ? value : ''}'),
          width: constraints.maxWidth,
          initialSelection: known ? value as String : null,
          enableFilter: true,
          requestFocusOnTap: true,
          menuHeight: 320,
          label: Text(_label(f)),
          helperText: f.helpLine ?? 'Type to search.',
          errorText: errors[_path(f)],
          dropdownMenuEntries: [
            for (final (id, label) in options)
              DropdownMenuEntry(value: id, label: label),
          ],
          onSelected: (v) => _set(f, v),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('field-${_path(f)}-${options.length}'),
      isExpanded: true,
      initialValue: known ? value as String : null,
      decoration: _decoration(f),
      hint: Text(
        f.only != null && options.isEmpty
            ? 'Choose the voyage first'
            : 'Choose…',
      ),
      items: [
        if (!f.required)
          const DropdownMenuItem<String>(child: Text('— None —')),
        for (final (id, label) in options)
          DropdownMenuItem(
            value: id,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => _set(f, v),
    );
  }

  Widget _multiRef(FieldSpec f, RefTarget target, Object? value) {
    final selected = {
      ...(value as List<Object?>? ?? const []).whereType<String>(),
    };
    final options = _refOptions(RefSpec(f.key, f.label, target));
    return _box(
      f,
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (id, label) in options)
            FilterChip(
              key: ValueKey('chip-${_path(f)}-$id'),
              label: Text(label),
              selected: selected.contains(id),
              onSelected: (on) {
                on ? selected.add(id) : selected.remove(id);
                _set(f, selected.toList()..sort());
              },
            ),
        ],
      ),
    );
  }

  Widget _localized(FieldSpec f, Object? value, {bool multiline = false}) {
    final map = switch (value) {
      final String s => {'en': s},
      final Map<String, Object?> m => {...m},
      _ => <String, Object?>{},
    };
    void update(String lang, String text) {
      text.trim().isEmpty ? map.remove(lang) : map[lang] = text;
      _set(f, map.isEmpty ? null : {...map});
    }

    final p = _path(f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('field-$p-en'),
          initialValue: map['en'] as String? ?? '',
          minLines: multiline ? 2 : 1,
          maxLines: multiline ? 6 : 1,
          decoration: InputDecoration(
            labelText: '${_label(f)} (English)',
            helperText: f.helpLine,
            helperMaxLines: 3,
            errorText: errors[p],
            border: const OutlineInputBorder(),
          ),
          onChanged: (t) => update('en', t),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('field-$p-fil'),
          initialValue: map['fil'] as String? ?? '',
          minLines: multiline ? 2 : 1,
          maxLines: multiline ? 6 : 1,
          decoration: InputDecoration(
            labelText: '${f.label} (Tagalog, optional)',
            helperText: 'Leave empty to show the English.',
            border: const OutlineInputBorder(),
          ),
          onChanged: (t) => update('fil', t),
        ),
      ],
    );
  }

  Widget _localizedList(LocalizedListSpec f, Object? value) {
    final items = (value as List<Object?>? ?? const []).toList();
    return _box(
      f,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('None yet.'),
            ),
          for (final (i, item) in items.indexed)
            Padding(
              // The length is part of the key so removing an item rebuilds
              // the inputs below it with their own text.
              key: ValueKey('${_path(f)}.$i.${items.length}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _localizedItem(f, items, i, item)),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      items.removeAt(i);
                      _set(f, [...items]);
                    },
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('add-${_path(f)}'),
              onPressed: () => _set(f, [
                ...items,
                <String, Object?>{'en': ''},
              ]),
              icon: const Icon(Icons.add),
              label: Text('Add ${f.itemLabel.toLowerCase()}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localizedItem(
    LocalizedListSpec f,
    List<Object?> items,
    int i,
    Object? item,
  ) {
    final box = <String, Object?>{'text': item};
    return SpecForm(
      fields: [
        LocalizedSpec('text', '${f.itemLabel} ${i + 1}', multiline: true),
      ],
      draft: box,
      data: data,
      errors: errors,
      path: '${_path(f)}.$i',
      onChanged: () {
        items[i] = box['text'] ?? <String, Object?>{'en': ''};
        _set(f, [...items]);
      },
    );
  }

  Widget _checkboxes(FieldSpec f, List<Choice> choices, Object? value) {
    final selected = [
      ...(value as List<Object?>? ?? const []).whereType<String>(),
    ];
    final all = [
      ...choices,
      for (final code in selected)
        if (!choices.any((c) => c.value == code)) Choice(code, code),
    ];
    return _box(
      f,
      Wrap(
        children: [
          for (final c in all)
            SizedBox(
              width: 280,
              child: CheckboxListTile(
                key: ValueKey('check-${_path(f)}-${c.value}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(c.label),
                value: selected.contains(c.value),
                onChanged: (on) {
                  final next = {...selected};
                  on == true
                      ? next.add(c.value as String)
                      : next.remove(c.value);
                  // Stored in the list's order, unknown codes last.
                  _set(f, [
                    for (final x in all)
                      if (next.contains(x.value)) x.value as String,
                  ]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _phones(FieldSpec f, Object? value) {
    final numbers = [
      ...(value as List<Object?>? ?? const []).whereType<String>(),
    ];
    final rows = numbers.isEmpty ? [''] : numbers;
    void store(List<String> next) => _set(f, [
      for (final n in next)
        if (n.trim().isNotEmpty) n.trim(),
    ]);
    return _box(
      f,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, n) in rows.indexed)
            Padding(
              key: ValueKey('${_path(f)}.$i.${rows.length}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('phone-${_path(f)}-$i'),
                      initialValue: n,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.call_outlined),
                        hintText: f.example,
                        errorText:
                            n.trim().isEmpty ||
                                RegExp(r'^\+?[0-9]{3,15}$')
                                    .hasMatch(dialableNumber(n))
                            ? null
                            : 'This number cannot be dialled. Use digits, e.g. 0917 123 4567',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (t) {
                        final next = [...rows]..[i] = t;
                        store(next);
                      },
                    ),
                  ),
                  if (rows.length > 1 || n.isNotEmpty)
                    IconButton(
                      tooltip: 'Remove this number',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => store([...rows]..removeAt(i)),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('addPhone-${_path(f)}'),
              // An empty box appears; it is saved once a number is typed.
              onPressed: rows.last.trim().isEmpty
                  ? null
                  : () {
                      draft[f.key] = [...numbers, ' '];
                      onChanged();
                    },
              icon: const Icon(Icons.add),
              label: const Text('Add another number'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _days(FieldSpec f, Object? value) {
    final days = {...(value as List<Object?>? ?? const []).whereType<int>()};
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _box(
      f,
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              key: ValueKey('day-${_path(f)}-$d'),
              label: Text(names[d - 1]),
              selected: days.contains(d),
              onSelected: (on) {
                on ? days.add(d) : days.remove(d);
                _set(f, days.toList()..sort());
              },
            ),
          TextButton(
            key: ValueKey('everyDay-${_path(f)}'),
            onPressed: () => _set(f, [1, 2, 3, 4, 5, 6, 7]),
            child: const Text('Every day'),
          ),
        ],
      ),
    );
  }

  Widget _geo(
    BuildContext context,
    FieldSpec f,
    Object? value,
    String? townKey,
  ) {
    final map = value is Map<String, Object?>
        ? value
        : const <String, Object?>{};
    final lat = (map['lat'] as num?)?.toDouble();
    final lng = (map['lng'] as num?)?.toDouble();
    final set = lat != null && lng != null;

    LatLng? townCenter() {
      final town = townKey == null
          ? null
          : data.rows['municipalities']?[draft[townKey]];
      final loc = town?['location'];
      if (loc is! Map<String, Object?>) return null;
      return LatLng(
        (loc['lat']! as num).toDouble(),
        (loc['lng']! as num).toDouble(),
      );
    }

    double round6(double v) => (v * 1e6).round() / 1e6;

    void updateRaw(String key, String text) {
      final next = {...map};
      if (text.trim().isEmpty) {
        next.remove(key);
      } else {
        final n = double.tryParse(text.trim());
        if (n == null) return _error(f, 'Enter decimal degrees, e.g. 12.4012');
        next[key] = n;
      }
      if (next.length == 1) {
        draft[f.key] = next;
        return _error(f, 'Enter both latitude and longitude');
      }
      _set(f, next.isEmpty ? null : next);
    }

    return _box(
      f,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(set ? Icons.place : Icons.location_off_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  set
                      ? 'Set on the map (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})'
                      : 'Not set yet',
                  key: ValueKey('geoStatus-${_path(f)}'),
                ),
              ),
              FilledButton.tonalIcon(
                key: ValueKey('pickOnMap-${_path(f)}'),
                icon: const Icon(Icons.map_outlined),
                label: Text(set ? 'Change on map' : 'Pick on map'),
                onPressed: () async {
                  final picked = await showMapPicker(
                    context,
                    title: f.label == 'Location'
                        ? 'Pick the location'
                        : f.label,
                    initial: set ? LatLng(lat, lng) : null,
                    center: townCenter(),
                  );
                  if (picked != null) {
                    _set(f, {
                      'lat': round6(picked.latitude),
                      'lng': round6(picked.longitude),
                    });
                  }
                },
              ),
              if (set)
                TextButton(
                  onPressed: () => _set(f, null),
                  child: const Text('Clear'),
                ),
            ],
          ),
          ExpansionTile(
            key: ValueKey('geoAdvanced-${_path(f)}'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Advanced: type the coordinates'),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              Row(
                children: [
                  for (final (key, label) in [
                    ('lat', 'Latitude'),
                    ('lng', 'Longitude'),
                  ]) ...[
                    Expanded(
                      child: TextFormField(
                        // Rebuilt after a map pick so the boxes show the new spot.
                        key: ValueKey('field-${_path(f)}-$key-${map[key]}'),
                        initialValue: map[key] == null ? '' : '${map[key]}',
                        decoration: InputDecoration(
                          labelText: label,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (t) => updateRaw(key, t),
                      ),
                    ),
                    if (key == 'lat') const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _objectList(BuildContext context, ObjectListSpec f, Object? value) {
    final items = [
      for (final i in (value as List<Object?>? ?? const []))
        if (i is Map<String, Object?>) i,
    ];
    void store() {
      if (f.itemId case final makeId?) {
        final used = {for (final i in items) ?i['id'] as String?};
        for (final (n, item) in items.indexed) {
          if (item['id'] == null) item['id'] = uniqueId(makeId(item, n), used);
        }
      }
      _set(f, items);
    }

    return _box(
      f,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('None yet.'),
            ),
          for (final (i, item) in items.indexed)
            Card(
              key: ObjectKey(item),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${f.itemLabel} ${i + 1}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Move up',
                          onPressed: i == 0
                              ? null
                              : () {
                                  items.insert(i - 1, items.removeAt(i));
                                  store();
                                },
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () {
                            items.removeAt(i);
                            store();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SpecForm(
                      fields: f.fields,
                      draft: item,
                      data: data,
                      errors: errors,
                      path: '${_path(f)}.$i',
                      index: i,
                      count: items.length,
                      onChanged: store,
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('add-${_path(f)}'),
              onPressed: () {
                items.add(<String, Object?>{});
                store();
              },
              icon: const Icon(Icons.add),
              label: Text('Add ${f.itemLabel.toLowerCase()}'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A peso amount typed by staff: "650", "₱650", "1,200" or "650.50".
num? parsePeso(String text) {
  final n = num.tryParse(
    text.trim().replaceAll(',', '').replaceAll('₱', '').trim(),
  );
  if (n == null || n < 0) return null;
  return n == n.roundToDouble() ? n.round() : n;
}

/// A text field whose text follows [value] while it is not being typed in
/// (used for the automatic ID).
class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    super.key,
    required this.value,
    required this.decoration,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_SyncedTextField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focus,
    enabled: widget.enabled,
    decoration: widget.decoration,
    onChanged: widget.onChanged,
  );
}

/// A usual amount, or "from … to …" when "It varies" is on.
class _RangeInput extends StatefulWidget {
  const _RangeInput({
    super.key,
    required this.spec,
    required this.value,
    required this.label,
    required this.help,
    required this.error,
    required this.onValue,
    required this.onError,
  });

  final RangeSpec spec;
  final Object? value;
  final String label;
  final String? help;
  final String? error;
  final ValueChanged<Object?> onValue;
  final ValueChanged<String> onError;

  @override
  State<_RangeInput> createState() => _RangeInputState();
}

class _RangeInputState extends State<_RangeInput> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  late bool _varies;

  @override
  void initState() {
    super.initState();
    final (min, max) = switch (widget.value) {
      final num n => ('$n', '$n'),
      final Map<String, Object?> m => (
        '${m['min'] ?? ''}',
        '${m['max'] ?? ''}',
      ),
      _ => ('', ''),
    };
    _varies = min != max;
    _min = TextEditingController(text: min);
    _max = TextEditingController(text: _varies ? max : '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  num? _parse(String t) {
    final n = parsePeso(t);
    return n == null ? null : (widget.spec.pesos ? n : n.round());
  }

  void _changed() {
    final minText = _min.text.trim();
    final maxText = _varies ? _max.text.trim() : '';
    if (minText.isEmpty && maxText.isEmpty) return widget.onValue(null);
    final min = _parse(minText);
    final max = maxText.isEmpty ? min : _parse(maxText);
    if (min == null || max == null) {
      return widget.onError(
        'Enter numbers only, e.g. ${widget.spec.example ?? 50}',
      );
    }
    if (max < min) return widget.onError('"To" must not be less than "From"');
    widget.onValue(min == max ? min : {'min': min, 'max': max});
  }

  String? _hours(String text) {
    if (widget.spec.pesos) return null;
    final n = int.tryParse(text.trim());
    return n == null || n < 60 ? null : '= ${hoursAndMinutes(n)}';
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.spec.pesos ? '₱ ' : null;
    final unit = widget.spec.pesos ? null : 'min';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.help,
        helperMaxLines: 3,
        errorText: widget.error,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('${widget.key}-min'),
                  controller: _min,
                  decoration: InputDecoration(
                    labelText: _varies ? 'From' : 'Usual amount',
                    prefixText: prefix,
                    suffixText: _hours(_min.text) ?? unit,
                  ),
                  onChanged: (_) => setState(_changed),
                ),
              ),
              if (_varies) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: ValueKey('${widget.key}-max'),
                    controller: _max,
                    decoration: InputDecoration(
                      labelText: 'To',
                      prefixText: prefix,
                      suffixText: _hours(_max.text) ?? unit,
                    ),
                    onChanged: (_) => setState(_changed),
                  ),
                ),
              ],
            ],
          ),
          SwitchListTile(
            key: ValueKey('${widget.key}-varies'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('It varies'),
            value: _varies,
            onChanged: (v) => setState(() {
              _varies = v;
              if (!v) _max.clear();
              _changed();
            }),
          ),
        ],
      ),
    );
  }
}
