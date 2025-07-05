import 'package:flutter/material.dart';
import 'package:quran_app/features/sura_list/view/widgets/sura_list_item.dart';

import '../model/sources/sura_information.dart';
class SuraListPage extends StatelessWidget {
  const SuraListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'সকল সূরা',
          style: TextStyle(fontFamily: 'SolaimanLipi'),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: allSuras.length,
        itemBuilder: (context, index) {
          final sura = allSuras[index];
          return SuraListItem(sura: sura);
        },
        // This adds a clean divider between each item
        separatorBuilder: (context, index) {
          return Divider(
            height: 1,
            thickness: 0.5,
            indent: 16, // Does not start from the very edge
            endIndent: 16,
          );
        },
      ),
    );
  }
}