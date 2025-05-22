import 'package:flutter/material.dart';

class SongThumbnail extends StatelessWidget {
  final bool isSelected;

  const SongThumbnail({super.key, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.purple : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note),
    );
  }
}