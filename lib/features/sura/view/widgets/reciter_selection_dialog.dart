import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quran/viewmodel/reciter_providers.dart';

class ReciterSelectionDialog extends ConsumerWidget {
  const ReciterSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReciterId = ref.watch(selectedReciterProvider);
    final selectedReciterName = reciters.entries
        .firstWhere((entry) => entry.value == selectedReciterId,
            orElse: () => reciters.entries.first)
        .key;

    return AlertDialog(
      title: const Text(
        'ক্বারী নির্বাচন করুন',
        style:
            TextStyle(fontFamily: 'SolaimanLipi', fontWeight: FontWeight.bold),
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
              value: reciterName,
              groupValue: selectedReciterName,
              onChanged: (String? value) {
                if (value != null && reciters.containsKey(value)) {
                  ref.read(selectedReciterProvider.notifier).state =
                      reciters[value]!;

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
            'বন্ধ করুন',
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
