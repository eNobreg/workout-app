import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A card widget for inputting weight and reps for a set.
/// Used for both adding new sets and editing existing ones.
class SetInputCard extends StatefulWidget {
  /// Initial weight value (for editing).
  final double? initialWeight;

  /// Initial reps value (for editing).
  final int? initialReps;

  /// Callback when set is saved with valid values.
  final void Function(double weight, int reps) onSave;

  /// Optional callback for cancel action.
  final VoidCallback? onCancel;

  /// Button text (e.g., "Save Set" or "Update Set").
  final String saveButtonText;

  /// Whether to show cancel button.
  final bool showCancelButton;

  const SetInputCard({
    super.key,
    this.initialWeight,
    this.initialReps,
    required this.onSave,
    this.onCancel,
    this.saveButtonText = 'Save Set',
    this.showCancelButton = false,
  });

  @override
  State<SetInputCard> createState() => _SetInputCardState();
}

class _SetInputCardState extends State<SetInputCard> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter weight';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight < 0) {
      return 'Weight cannot be negative';
    }
    return null;
  }

  String? _validateReps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter reps';
    }
    final reps = int.tryParse(value);
    if (reps == null || reps <= 0) {
      return 'Reps must be > 0';
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final weight = double.parse(_weightController.text);
      final reps = int.parse(_repsController.text);
      widget.onSave(weight, reps);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Weight field
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'lbs',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: _validateWeight,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reps field
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: _validateReps,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSave(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.showCancelButton && widget.onCancel != null) ...[
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(widget.saveButtonText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dialog wrapper for SetInputCard used for editing sets.
class SetInputDialog extends StatelessWidget {
  final String title;
  final double? initialWeight;
  final int? initialReps;

  const SetInputDialog({
    super.key,
    required this.title,
    this.initialWeight,
    this.initialReps,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SetInputCard(
          initialWeight: initialWeight,
          initialReps: initialReps,
          saveButtonText: 'Save',
          showCancelButton: true,
          onSave: (weight, reps) {
            Navigator.of(context).pop({'weight': weight, 'reps': reps});
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      actionsPadding: EdgeInsets.zero,
      actions: const [], // Actions are in the card
    );
  }
}
