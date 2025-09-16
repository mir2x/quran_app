import 'package:flutter/material.dart';

class AyahPlaceholder extends StatelessWidget {
  const AyahPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 150.0, // Adjust to your average card height
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 16, width: double.infinity, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Container(height: 16, width: 200, color: Colors.grey.shade200),
          ],
        ),
      ),
    );
  }
}