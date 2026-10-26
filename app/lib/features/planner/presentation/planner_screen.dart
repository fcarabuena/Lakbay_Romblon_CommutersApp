import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/providers.dart';
import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../application/planner_providers.dart';

const _otherPlace = '__other__';

/// The trip planner form: hometown, Manila end, date, travellers, class.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customName = TextEditingController();
  final _customFare = TextEditingController();
  final _customMinutes = TextEditingController();

  TripDirection _direction = TripDirection.toManila;
  String? _municipalityId;
  late String _manilaChoice;
  late String _customHub;
  DateTime? _departure;
  TravellerGroup _travellers = const TravellerGroup();
  String? _fareClass;
  bool _travellerError = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(travelDataProvider);
    _manilaChoice = data.hubs.first.id;
    _customHub = data.hubs.first.id;

    final previous = ref.read(tripRequestProvider);
    if (previous != null) {
      _direction = previous.direction;
      _municipalityId = previous.municipalityId;
      _manilaChoice = previous.custom == null
          ? previous.manilaEndId
          : _otherPlace;
      _customHub = previous.custom?.nearestHubId ?? _customHub;
      _customName.text = previous.custom?.name ?? '';
      _departure = previous.departure;
      _travellers = previous.travellers;
      _fareClass = previous.preferredFareClass;
      if (previous.customFare case final fare?) {
        _customFare.text = '${fare.max ~/ 100}';
      }
      if (previous.customMinutes case final m?) {
        _customMinutes.text = '${m.max}';
      }
    }
  }

  @override
  void dispose() {
    _customName.dispose();
    _customFare.dispose();
    _customMinutes.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final now = ref.read(clockProvider)();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      initialDate: _departure ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure ?? now),
    );
    if (!mounted) return;
    setState(() {
      final t = time ?? const TimeOfDay(hour: 6, minute: 0);
      _departure = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    });
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    setState(() => _travellerError = _travellers.total == 0);
    if (!formOk || _travellerError) return;

    final isCustom = _manilaChoice == _otherPlace;
    final fare = parsePesoInput(_customFare.text);
    final minutes = int.tryParse(_customMinutes.text.trim());
    final request = TripRequest(
      direction: _direction,
      municipalityId: _municipalityId!,
      manilaEndId: isCustom ? _customHub : _manilaChoice,
      custom: isCustom
          ? CustomPlace(name: _customName.text.trim(), nearestHubId: _customHub)
          : null,
      customFare: isCustom && fare != null ? IntRange.exact(fare) : null,
      customMinutes: isCustom && minutes != null
          ? IntRange.exact(minutes)
          : null,
      departure: _departure,
      travellers: _travellers,
      preferredFareClass: _fareClass,
    );
    ref.read(tripRequestProvider.notifier).set(request);
    context.push('/plan/results');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(travelDataProvider);
    final towns = [...data.municipalities]
      ..sort((a, b) => a.name.compareTo(b.name));
    final classes = {
      for (final f in data.shipFares)
        if (!f.isRoom) f.fareClass,
    }.toList()..sort();
    final toManila = _direction == TripDirection.toManila;
    final isCustom = _manilaChoice == _otherPlace;
    const gap = SizedBox(height: 16);

    final hometownField = DropdownButtonFormField<String>(
      key: const Key('hometown'),
      initialValue: _municipalityId,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.hometownLabel),
      items: [
        for (final m in towns)
          DropdownMenuItem(value: m.id, child: Text('${m.name} (${m.island})')),
      ],
      validator: (v) => v == null ? l10n.errorPickHometown : null,
      onChanged: (v) => setState(() => _municipalityId = v),
    );

    final manilaField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('manilaEnd'),
          initialValue: _manilaChoice,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: toManila ? l10n.manilaEndTo : l10n.manilaEndFrom,
          ),
          items: [
            for (final h in data.hubs)
              DropdownMenuItem(
                value: h.id,
                child: Text('${h.name} (${h.area})'),
              ),
            DropdownMenuItem(value: _otherPlace, child: Text(l10n.otherPlace)),
          ],
          onChanged: (v) => setState(() => _manilaChoice = v!),
        ),
        if (isCustom) ...[
          gap,
          TextFormField(
            key: const Key('customName'),
            controller: _customName,
            decoration: InputDecoration(labelText: l10n.customPlaceName),
            validator: (v) => isCustom && (v ?? '').trim().isEmpty
                ? l10n.errorCustomName
                : null,
          ),
          gap,
          DropdownButtonFormField<String>(
            initialValue: _customHub,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.customNearestHub),
            items: [
              for (final h in data.hubs)
                DropdownMenuItem(value: h.id, child: Text(h.name)),
            ],
            onChanged: (v) => setState(() => _customHub = v!),
          ),
          gap,
          TextFormField(
            controller: _customFare,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.customFareLabel),
            validator: (v) =>
                (v ?? '').trim().isNotEmpty && parsePesoInput(v!) == null
                ? l10n.errorNumber
                : null,
          ),
          gap,
          TextFormField(
            controller: _customMinutes,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.customMinutesLabel),
            validator: (v) =>
                (v ?? '').trim().isNotEmpty && int.tryParse(v!.trim()) == null
                ? l10n.errorNumber
                : null,
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.plannerTitle)),
      // Not a lazy ListView: off-screen fields must stay mounted so the Form
      // still validates them after the user scrolls down to the button.
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TripDirection>(
                segments: [
                  ButtonSegment(
                    value: TripDirection.toManila,
                    icon: const Icon(Icons.location_city),
                    label: Text(l10n.directionToManila),
                  ),
                  ButtonSegment(
                    value: TripDirection.toRomblon,
                    icon: const Icon(Icons.home),
                    label: Text(l10n.directionToRomblon),
                  ),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() => _direction = s.first),
              ),
              gap,
              // Fields follow the direction of travel: origin first.
              if (toManila) ...[
                hometownField,
                gap,
                manilaField,
              ] else ...[
                manilaField,
                gap,
                hometownField,
              ],
              gap,
              SectionCard(
                title: l10n.departureLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _departure == null
                          ? l10n.departureAny
                          : formatDateTime(l10n, _departure!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDeparture,
                          icon: const Icon(Icons.event),
                          label: Text(l10n.departurePick),
                        ),
                        if (_departure != null)
                          TextButton(
                            onPressed: () => setState(() => _departure = null),
                            child: Text(l10n.departureClear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              gap,
              SectionCard(
                title: l10n.travellersLabel,
                child: Column(
                  children: [
                    for (final type in PassengerType.values)
                      CountStepper(
                        label: passengerLabel(l10n, type),
                        value: _travellers.count(type),
                        onChanged: (v) => setState(
                          () => _travellers = _travellers.withCount(type, v),
                        ),
                      ),
                    if (_travellerError) ...[
                      const SizedBox(height: 8),
                      Notice(l10n.errorNoTravellers, tone: NoticeTone.error),
                    ],
                  ],
                ),
              ),
              gap,
              DropdownButtonFormField<String?>(
                initialValue: _fareClass,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.fareClassLabel),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.fareClassAny)),
                  for (final c in classes)
                    DropdownMenuItem(
                      value: c,
                      child: Text(fareClassLabel(l10n, c)),
                    ),
                ],
                onChanged: (v) => setState(() => _fareClass = v),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('findRoutes'),
                onPressed: _submit,
                icon: const Icon(Icons.search),
                label: Text(l10n.findRoutes),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/plan/budget'),
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(l10n.budgetTitle),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('planMyTrips'),
                onPressed: () => context.push('/plan/trips'),
                icon: const Icon(Icons.bookmark_outline),
                label: Text(l10n.myTrips),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
