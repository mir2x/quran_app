import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/services/auto_scroll_service.dart';
import '../../viewmodel/sura_viewmodel.dart';

class AutoScrollController extends ConsumerWidget {
  final AutoScrollService autoScrollService;

  const AutoScrollController({
    super.key,
    required this.autoScrollService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(autoScrollSpeedProvider);
    final isActive = ref.watch(autoScrollActiveProvider);

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              isActive ? Icons.pause : Icons.play_arrow,
              color: Colors.green.shade700,
            ),
            onPressed: autoScrollService.toggleAutoScroll,
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: autoScrollService.decreaseSpeed,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${speed.toInt()}x',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: autoScrollService.increaseSpeed,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              autoScrollService.stopAutoScroll();
              ref.read(autoScrollControllerVisibleProvider.notifier).state = false;
            },
          ),
        ],
      ),
    );
  }
}