import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../sura/view/sura_page.dart';
import '../../../sura/view/widgets/search_page.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isLandscape;
  const CustomAppBar({super.key, this.isLandscape = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          iconSize: isLandscape ? 20.0 : 24.0,
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'কুরআন মাজীদ',
        style: TextStyle(
          fontFamily: 'SolaimanLipi',
          fontSize: isLandscape ? 18.0 : 22.sp,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
            icon: const Icon(Icons.search),
            iconSize: isLandscape ? 20.0 : 24.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            }),
        IconButton(
            icon: const Icon(Icons.nightlight_outlined),
            iconSize: isLandscape ? 20.0 : 24.0,
            onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.g_translate),
          iconSize: isLandscape ? 20.0 : 24.0,
          onPressed: () {
            final int suraNumber = ref.watch(currentSuraProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahPage(suraNumber: suraNumber),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
