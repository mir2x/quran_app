import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quran/viewmodel/ayah_highlight_viewmodel.dart';
import '../../../quran/viewmodel/reciter_providers.dart';

class ReciterSelectionDialog extends ConsumerWidget {
  const ReciterSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find the key (reciter name) that corresponds to the selected reciter ID.
    final selectedReciterId = ref.watch(selectedReciterProvider);
    final selectedReciterName = reciters.entries
        .firstWhere((entry) => entry.value == selectedReciterId, orElse: () => reciters.entries.first)
        .key;

    return AlertDialog(
      title: const Text(
        'ক্বারী নির্বাচন করুন',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: reciters.keys.map((reciterName) {
            return RadioListTile<String>(
              title: Text(
                reciterName,
                style: const TextStyle(fontFamily: 'SolaimanLipi'),
              ),
              value: reciterName, // The value is the reciter's name
              groupValue: selectedReciterName, // The group value is also the reciter's name
              onChanged: (String? value) {
                if (value != null && reciters.containsKey(value)) {
                  // When changed, update the provider with the corresponding ID.
                  ref.read(selectedReciterProvider.notifier).state = reciters[value]!;
                  // Optionally close the dialog after selection
                  Navigator.of(context).pop();
                }
              },
              activeColor: Colors.green.shade700,
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'বন্ধ করুন', // "Close" in Bengali
            style: TextStyle(
                fontFamily: 'SolaimanLipi', color: Colors.green.shade800),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      contentPadding: const EdgeInsets.only(top: 20.0, right: 8.0, left: 8.0),
    );
  }
}