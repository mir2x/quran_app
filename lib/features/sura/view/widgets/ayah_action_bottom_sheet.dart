import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';
import '../../model/ayah.dart';
import '../../viewmodel/sura_reciter_viewmodel.dart';


class AyahActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  AyahActionItem({required this.icon, required this.label, required this.onTap});
}

void showAyahActionBottomSheet(BuildContext context, int suraNumber, Ayah ayah, String suraName, WidgetRef ref) {
  final int selectedStartAyah = ayah.ayah;
  final int selectedEndAyah = ayah.ayah;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (BuildContext bc) {
      final List<AyahActionItem> actions = [
        // ... (Define actions as before)
        AyahActionItem(icon: Icons.bookmark_border, label: 'বুকমার্ক', onTap: () => print('Bookmark Ayah ${ayah.ayah}')),
        AyahActionItem(icon: Icons.play_arrow, label: 'অডিও শুনুন', onTap: () async {
          final audioPlayer = ref.read(suraAudioPlayerProvider);
          ref.read(selectedAudioSuraProvider.notifier).state = suraNumber;
          ref.read(selectedStartAyahProvider.notifier).state = selectedStartAyah;
          ref.read(selectedEndAyahProvider.notifier).state = selectedEndAyah;
          if (!context.mounted) return;
          Navigator.of(context).pop();
          await audioPlayer.playAyahs(
            selectedStartAyah,
            selectedEndAyah,
            context,
          );

        }),
        AyahActionItem(icon: Icons.menu_book, label: 'তাফসীর', onTap: () {
          // This call works perfectly with the new dynamic TafsirView

        }),
      ];

      return Container(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$suraName, আয়াত ${ayah.ayah.toBengaliDigit()}',
              style: const TextStyle(
                fontFamily: 'SolaimanLipi',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final item = actions[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    item.onTap();
                    Navigator.pop(bc);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 36, color: Colors.grey.shade700),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SolaimanLipi',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}