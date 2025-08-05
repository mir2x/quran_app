import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/font_settings_viewmodel.dart';


class FontChangeDialog extends ConsumerStatefulWidget {
  const FontChangeDialog({super.key});

  @override
  ConsumerState<FontChangeDialog> createState() => _FontChangeDialogState();
}

class _FontChangeDialogState extends ConsumerState<FontChangeDialog> {
  // --- Local state for the dialog ---
  late String _selectedLanguage;
  late String _selectedArabicFont;
  late String _selectedBengaliFont;
  late double _selectedArabicSize;
  late double _selectedBengaliSize;

  // --- Available options (use the EXACT family names from pubspec.yaml) ---
  final List<String> _languages = ['Arabic', 'Bengali'];
  final List<String> _arabicFonts = [
    'Al Mushaf Quran',
    'Al Qalam Kolkatta Quranic',
    'Al Qalam Quran',
    'Al Qalam Quran Majeed',
  ];
  final List<String> _bengaliFonts = [
    'SolaimanLipi',
    'Kalpurush',
    'Noto Sans Bengali',
    'Siyam Rupali',
  ];
  final List<double> _fontSizes = List.generate(15, (index) => 14.0 + (index * 2));

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languages.first;
    _selectedArabicFont = ref.read(arabicFontProvider);
    _selectedBengaliFont = ref.read(bengaliFontProvider);
    _selectedArabicSize = ref.read(arabicFontSizeProvider);
    _selectedBengaliSize = ref.read(bengaliFontSizeProvider);
  }

  void _onConfirm() {
    ref.read(arabicFontProvider.notifier).state = _selectedArabicFont;
    ref.read(bengaliFontProvider.notifier).state = _selectedBengaliFont;
    ref.read(arabicFontSizeProvider.notifier).state = _selectedArabicSize;
    ref.read(bengaliFontSizeProvider.notifier).state = _selectedBengaliSize;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = _selectedLanguage == 'Arabic';
    final List<String> currentFonts = isArabic ? _arabicFonts : _bengaliFonts;
    String currentFontSelection = isArabic ? _selectedArabicFont : _selectedBengaliFont;
    double currentSizeSelection = isArabic ? _selectedArabicSize : _selectedBengaliSize;

    if (!currentFonts.contains(currentFontSelection)) {
      currentFontSelection = currentFonts.first;
    }
    if (!_fontSizes.contains(currentSizeSelection)) {
      currentSizeSelection = _fontSizes.first;
    }

    return AlertDialog(
      title: const Text('ফন্ট পরিবর্তন', style: TextStyle(fontFamily: 'SolaimanLipi')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown<String>(
              label: 'ভাষা',
              value: _selectedLanguage,
              items: _languages,
              onChanged: (value) {
                if (value != null) setState(() => _selectedLanguage = value);
              },
            ),
            const SizedBox(height: 16),
            _buildDropdown<String>(
              label: 'ফন্ট',
              value: currentFontSelection,
              items: currentFonts,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (isArabic) _selectedArabicFont = value;
                    else _selectedBengaliFont = value;
                  });
                }
              },
              // *** KEY CHANGE HERE ***
              // Use standard TextStyle with fontFamily for the preview
              itemBuilder: (font) => Text(font, style: TextStyle(fontFamily: font)),
            ),
            const SizedBox(height: 16),
            _buildDropdown<double>(
              label: 'সাইজ',
              value: currentSizeSelection,
              items: _fontSizes,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (isArabic) _selectedArabicSize = value;
                    else _selectedBengaliSize = value;
                  });
                }
              },
              itemBuilder: (size) => Text(size.toInt().toString()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাতিল', style: TextStyle(fontFamily: 'SolaimanLipi')),
        ),
        FilledButton(
          onPressed: _onConfirm,
          child: const Text('নিশ্চিত করুন', style: TextStyle(fontFamily: 'SolaimanLipi')),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    Widget Function(T)? itemBuilder,
  }) {
    // This helper method remains unchanged and works perfectly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'SolaimanLipi', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemBuilder != null ? itemBuilder(item) : Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}