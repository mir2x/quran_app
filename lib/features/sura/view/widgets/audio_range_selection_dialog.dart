// features/sura/view/widgets/audio_range_selection_dialog.dart

import 'package:flutter/material.dart';

// Utility function to convert numbers to Bengali digits.
String toBengaliDigit(int number) {
  const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number.toString().split('').map((digit) {
    return bengaliDigits[int.parse(digit)];
  }).join('');
}


class AudioRangeSelectionDialog extends StatefulWidget {
  final int totalAyahs;

  const AudioRangeSelectionDialog({
    super.key,
    required this.totalAyahs,
  });

  @override
  State<AudioRangeSelectionDialog> createState() => _AudioRangeSelectionDialogState();
}

class _AudioRangeSelectionDialogState extends State<AudioRangeSelectionDialog> {
  // State variables
  late int _selectedStartAyah;
  late int _selectedEndAyah;
  late FixedExtentScrollController _startController;
  late FixedExtentScrollController _endController;

  bool _isFullSura = false;
  int _repeatCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedStartAyah = 1;
    _selectedEndAyah = widget.totalAyahs > 1 ? 2 : 1; // Default to a small range

    _startController = FixedExtentScrollController(initialItem: _selectedStartAyah - 1);
    _endController = FixedExtentScrollController(initialItem: _selectedEndAyah - 1);
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onFullSuraChanged(bool? value) {
    setState(() {
      _isFullSura = value ?? false;
      if (_isFullSura) {
        // If "Full Surah" is checked, select all ayahs
        _selectedStartAyah = 1;
        _selectedEndAyah = widget.totalAyahs;
        _startController.animateToItem(
          _selectedStartAyah - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _endController.animateToItem(
          _selectedEndAyah - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Remove default padding
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPickerUI(),
            const SizedBox(height: 16),
            _buildFullSuraCheckbox(),
            _buildRepeatStepper(),
            const SizedBox(height: 16),
            _buildListenButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerUI() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('শুরু', style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 18, fontWeight: FontWeight.bold)),
                Text('শেষ', style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                _buildPickerColumn(
                  controller: _startController,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedStartAyah = index + 1;
                      if (_isFullSura) _isFullSura = false; // Uncheck if manually changed
                      if (_selectedStartAyah > _selectedEndAyah) {
                        _selectedEndAyah = _selectedStartAyah;
                        _endController.animateToItem(_selectedEndAyah - 1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                      }
                    });
                  },
                ),
                const VerticalDivider(width: 1),
                _buildPickerColumn(
                  controller: _endController,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedEndAyah = index + 1;
                      if (_isFullSura) _isFullSura = false; // Uncheck if manually changed
                      if (_selectedEndAyah < _selectedStartAyah) {
                        _selectedStartAyah = _selectedEndAyah;
                        _startController.animateToItem(_selectedStartAyah - 1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerColumn({
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
  }) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // This container creates the highlight effect for the selected item
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade700.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final ayahNumber = index + 1;
                final isSelected = (_selectedStartAyah == ayahNumber && controller == _startController) ||
                    (_selectedEndAyah == ayahNumber && controller == _endController);
                return Center(
                  child: Text(
                    toBengaliDigit(ayahNumber),
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'SolaimanLipi',
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
              childCount: widget.totalAyahs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSuraCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _isFullSura,
            onChanged: _onFullSuraChanged,
            activeColor: Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _onFullSuraChanged(!_isFullSura),
          child: const Text(
            'সম্পূর্ণ সূরা',
            style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'আয়াতের পুনরাবৃত্তি',
          style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 16),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () {
            if (_repeatCount > 0) {
              setState(() => _repeatCount--);
            }
          },
          color: Colors.grey.shade600,
        ),
        Text(
          toBengaliDigit(_repeatCount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700, fontFamily: 'SolaimanLipi'),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            setState(() => _repeatCount++);
          },
          color: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildListenButton() {
    return ElevatedButton(
      child: const Text(
        'অডিও শুনুন',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        // Add your play logic here
        print('Play pressed: Surah from $_selectedStartAyah to $_selectedEndAyah, repeating $_repeatCount times.');
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}