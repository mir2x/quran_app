import 'package:flutter/material.dart';
import 'package:quran_app/features/sura/view/widgets/translation_selection_dialog.dart';
import '../../model/grid_item_data.dart'; // Make sure this path is correct

void showDetailsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    // isScrollControlled can be false now if you are sure content fits,
    // but true doesn't hurt and gives a bit more flexibility if needed by the system.
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
    // Wrap with SingleChildScrollView to allow the content to determine its height
    // and then constrain the BottomSheet itself.
    // This is a common pattern for bottom sheets with dynamic content height.
    return SingleChildScrollView( // Added to correctly size the content
      child: Container(
        padding: const EdgeInsets.only(bottom: 16), // Optional: Add some padding at the very bottom
        child: Column(
          mainAxisSize: MainAxisSize.min, // CRUCIAL: Column takes minimum vertical space
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch horizontally
          children: [
            _buildDragHandle(),
            _DetailsSection(
              title: 'ফিচার',
              items: [
                GridItemData(icon: Icons.search, label: 'অনুসন্ধান', onTap: () {}),
                GridItemData(icon: Icons.fullscreen_exit_outlined, label: 'স্ক্রীন বড়-ছোট', onTap: () {}),
              ],
            ),
            _DetailsSection(
              title: 'ভিউ',
              items: [
                GridItemData(icon: Icons.format_size, label: 'ফন্ট বড়/ছোট', onTap: () {}),
              ],
            ),
            _DetailsSection(
              title: 'সেটিংস',
              items: [
                GridItemData(icon: Icons.translate_outlined, label: 'অনুবাদক পরিবর্তন', onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const TranslatorSelectionDialog(),
                  );
                }),
                GridItemData(icon: Icons.person_outline, label: 'কারী পরিবর্তন', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Align( // Center the drag handle
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8), // Minimal vertical margin
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<GridItemData> items;

  const _DetailsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // CRUCIAL: Section takes minimum vertical space
      children: [
        Container(
          width: double.infinity, // Title background spans width
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical padding
          color: Colors.blue.shade50,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'SolaimanLipi',
              fontSize: 14, // Further reduced font size for compactness
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true, // IMPORTANT for GridView inside a Column
          physics: const NeverScrollableScrollPhysics(), // IMPORTANT to disable GridView's own scrolling
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Adjusted padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3, // Reduced spacing
            mainAxisSpacing: 4,  // Reduced spacing
            childAspectRatio: 1.1, // Adjust for content (width/height), might need tuning
            // e.g., 1.0 for square, >1 for wider, <1 for taller items
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              borderRadius: BorderRadius.circular(6), // Slightly smaller radius
              onTap: item.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 28, color: Colors.green.shade700), // Further reduced icon size
                  const SizedBox(height: 4), // Further reduced spacing
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SolaimanLipi',
                      fontSize: 12, // Further reduced font size
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2, // Allow text to wrap if necessary
                    overflow: TextOverflow.ellipsis, // Handle overflow
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
