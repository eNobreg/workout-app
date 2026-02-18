import 'package:flutter/material.dart';

/// Dialog for inputting the number of days in a rotation cycle.
class RotationDaysInputDialog extends StatefulWidget {
  final int initialDays;

  const RotationDaysInputDialog({
    super.key,
    this.initialDays = 7,
  });

  @override
  State<RotationDaysInputDialog> createState() =>
      _RotationDaysInputDialogState();
}

class _RotationDaysInputDialogState extends State<RotationDaysInputDialog> {
  late int _selectedDays;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    _controller = TextEditingController(text: _selectedDays.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateDays(int value) {
    if (value >= 1 && value <= 30) {
      setState(() {
        _selectedDays = value;
        _controller.text = value.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Rotation Cycle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many days in your rotation?'),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _updateDays(parsed);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Enter 1-30',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: _selectedDays > 1
                    ? () => _updateDays(_selectedDays - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_selectedDays days',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _selectedDays < 30
                    ? () => _updateDays(_selectedDays + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedDays),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
