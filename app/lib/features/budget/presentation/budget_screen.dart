import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakbay_core/lakbay_core.dart';

import '../../../core/ui/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../planner/application/planner_providers.dart';

/// Checks whether the traveller's cash covers fares, fees, food and a buffer.
///
/// With a plan, fares and fees come from it (upper estimate). Without one the
/// traveller types their own estimate.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key, this.planId});

  final String? planId;

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  static const _bufferMinimum = 50000; // ₱500

  final _cash = TextEditingController();
  // Default food cost is the traveller's own estimate, editable.
  final _food = TextEditingController(text: '150');
  final _extras = TextEditingController();
  final _manualFares = TextEditingController();
  final _manualFees = TextEditingController();
  int? _meals;
  int _bufferPercent = 20;

  @override
  void dispose() {
    for (final c in [_cash, _food, _extras, _manualFares, _manualFees]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plan = widget.planId == null
        ? null
        : ref.watch(planByIdProvider(widget.planId!));
    final travellers = plan == null
        ? 1
        : ref.watch(tripRequestProvider)?.travellers.total ?? 1;
    final meals =
        _meals ?? BudgetCalculator.suggestedMeals(plan?.time.total.max ?? 0);

    final result = const BudgetCalculator().calculate(
      BudgetInput(
        cashOnHand: parsePesoInput(_cash.text) ?? 0,
        fares: plan?.fare.fares.max ?? parsePesoInput(_manualFares.text) ?? 0,
        fees: plan?.fare.fees ?? parsePesoInput(_manualFees.text) ?? 0,
        travellers: travellers,
        meals: meals,
        foodPerMeal: parsePesoInput(_food.text) ?? 0,
        bufferPercent: _bufferPercent,
        bufferMinimum: _bufferMinimum,
        extras: parsePesoInput(_extras.text) ?? 0,
      ),
    );

    void changed(String _) => setState(() {});
    TextField money(
      TextEditingController c,
      String label, {
      Key? key,
      String? hint,
    }) => TextField(
      key: key,
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '₱ ',
      ),
      onChanged: changed,
    );
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          money(_cash, l10n.budgetCash, key: const Key('budgetCash')),
          gap,
          Notice(plan != null ? l10n.budgetFromPlan : l10n.budgetNoPlan),
          if (plan == null) ...[
            gap,
            money(
              _manualFares,
              l10n.budgetManualFares,
              key: const Key('budgetManualFares'),
            ),
            gap,
            money(_manualFees, l10n.budgetManualFees),
          ],
          gap,
          money(_food, l10n.budgetFoodPerMeal),
          gap,
          CountStepper(
            label: l10n.budgetMeals,
            value: meals,
            onChanged: (v) => setState(() => _meals = v),
          ),
          gap,
          money(_extras, l10n.budgetExtras, hint: l10n.budgetExtrasHint),
          gap,
          Text(
            l10n.budgetBufferPercent(_bufferPercent),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Slider(
            value: _bufferPercent.toDouble(),
            min: 0,
            max: 50,
            divisions: 10,
            label: '$_bufferPercent%',
            onChanged: (v) => setState(() => _bufferPercent = v.round()),
          ),
          Text(l10n.budgetBufferMinimum(formatPesos(_bufferMinimum))),
          const SizedBox(height: 24),
          _ResultCard(result: result),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final BudgetResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (message, tone) = switch (result.status) {
      BudgetStatus.covered => (l10n.budgetCovered, NoticeTone.success),
      BudgetStatus.tight => (l10n.budgetTight, NoticeTone.warning),
      BudgetStatus.short => (l10n.budgetShort, NoticeTone.error),
    };
    final diff = result.difference;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Notice(
            message,
            tone: tone,
            key: Key('budgetStatus-${result.status.name}'),
          ),
          const SizedBox(height: 12),
          AmountRow(l10n.budgetFares, formatPesos(result.fares)),
          AmountRow(l10n.budgetFees, formatPesos(result.fees)),
          AmountRow(l10n.budgetFood, formatPesos(result.food)),
          if (result.extras > 0)
            AmountRow(l10n.budgetOther, formatPesos(result.extras)),
          AmountRow(l10n.budgetBuffer, formatPesos(result.buffer)),
          const Divider(),
          AmountRow(
            l10n.budgetNeeded,
            formatPesos(result.totalNeeded),
            emphasize: true,
          ),
          AmountRow(
            l10n.budgetYouHave,
            formatPesos(result.cashOnHand),
            emphasize: true,
          ),
          const SizedBox(height: 4),
          Text(
            diff >= 0
                ? l10n.budgetLeftover(formatPesos(diff))
                : l10n.budgetShortBy(formatPesos(-diff)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
