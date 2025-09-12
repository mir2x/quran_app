// features/sura/view/widgets/tafsir_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/tafsir_provider.dart';


class TafsirView extends ConsumerStatefulWidget {
  final int suraNumber;
  final int ayahNumber;

  const TafsirView({
    super.key,
    required this.suraNumber,
    required this.ayahNumber,
  });

  @override
  ConsumerState<TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends ConsumerState<TafsirView> {
  int? _expandedPanelIndex; // Use an index to track the open panel

  @override
  Widget build(BuildContext context) {
    final ayahIdentifier = AyahIdentifier(sura: widget.suraNumber, ayah: widget.ayahNumber);
    final tafsirAsyncValue = ref.watch(tafsirProvider(ayahIdentifier));

    return tafsirAsyncValue.when(
      data: (tafsirData) {
        return SingleChildScrollView(
          child: ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                if (_expandedPanelIndex == index) {
                  _expandedPanelIndex = null; // Close if already open
                } else {
                  _expandedPanelIndex = index; // Open the new one
                }
              });
            },
            animationDuration: const Duration(milliseconds: 300),
            elevation: 1,
            children: tafsirData.asMap().entries.map<ExpansionPanel>((entry) {
              int index = entry.key;
              var item = entry.value;
              return ExpansionPanel(
                canTapOnHeader: true,
                backgroundColor: const Color(0xFFE6F0E6),
                isExpanded: _expandedPanelIndex == index, // Check if this panel is the expanded one
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'SolaimanLipi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E4D2B),
                      ),
                    ),
                  );
                },
                body: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.content,
                    style: const TextStyle(
                      fontFamily: 'SolaimanLipi',
                      fontSize: 15,
                      height: 1.8,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}