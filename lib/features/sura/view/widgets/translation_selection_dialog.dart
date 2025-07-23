import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodel/sura_viewmodel.dart';

const List<String> availableTranslators = [
  'মুফতী তাকী উসমানী',
  'মাওলানা মুহিউদ্দিন খান',
  'ইসলামিক ফাউন্ডেশন',
];

class TranslatorSelectionDialog extends ConsumerWidget {
  const TranslatorSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTranslatorsProvider);
    return AlertDialog(
      title: const Text(
        'অনুবাদক নির্বাচন করুন',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableTranslators.map((translatorName) {
            return CheckboxListTile(
              title: Text(
                translatorName,
                style: const TextStyle(fontFamily: 'SolaimanLipi'),
              ),
              value: selected.contains(translatorName),
              onChanged: (bool? isSelected) {
                final currentSelection =
                List<String>.from(ref.read(selectedTranslatorsProvider));

                if (isSelected == true) {
                  currentSelection.add(translatorName);
                } else {
                  currentSelection.remove(translatorName);
                }

                ref.read(selectedTranslatorsProvider.notifier).state = currentSelection;
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