import 'package:flutter/material.dart';
import '../../model/grid_item_data.dart';

void showDetailsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) => const DetailsBottomSheet(),
  );
}

class DetailsBottomSheet extends StatelessWidget {
  const DetailsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _DetailsSection(
              title: 'ফিচার',
              items: [
                GridItemData(icon: Icons.play_circle_fill_outlined, label: 'বাংলা অনুবাদসহ অডিও', onTap: () {}),
                GridItemData(icon: Icons.search, label: 'অনুসন্ধান', onTap: () {}),
                GridItemData(icon: Icons.fullscreen_exit_outlined, label: 'স্ক্রীন বড়-ছোট', onTap: () {}),
              ],
            ),
            _DetailsSection(
              title: 'ভিউ',
              items: [
                GridItemData(icon: Icons.format_size, label: 'ফন্ট বড়/ছোট', onTap: () {}),
                GridItemData(icon: Icons.color_lens_outlined, label: 'রঙিন তাজউইদ', onTap: () {}),
                GridItemData(icon: Icons.visibility_off_outlined, label: 'ব্যাখ্যা ছাড়া', onTap: () {}),
                GridItemData(icon: Icons.mic_none_outlined, label: 'উচ্চারণ সহ দেখুন', onTap: () {}),
              ],
            ),
            _DetailsSection(
              title: 'সেটিংস',
              items: [
                GridItemData(icon: Icons.translate_outlined, label: 'অনুবাদক পরিবর্তন', onTap: () {}),
                GridItemData(icon: Icons.download_for_offline_outlined, label: 'ডাউনলোড কৃত', onTap: () {}),
                GridItemData(icon: Icons.person_outline, label: 'কারী পরিবর্তন', onTap: () {}),
                GridItemData(icon: Icons.auto_stories_outlined, label: 'তেলাওয়াত মোড', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// Reusable section widget to avoid code duplication
class _DetailsSection extends StatelessWidget {
  final String title;
  final List<GridItemData> items;

  const _DetailsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.blue.shade50,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'SolaimanLipi',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: item.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 40, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 14, color: Colors.grey.shade800),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}