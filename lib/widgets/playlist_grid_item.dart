import 'package:flutter/material.dart';

class PlaylistGridItem extends StatelessWidget {
  final VoidCallback onTap;

  const PlaylistGridItem({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
        ),
        child: const Center(child: Icon(Icons.playlist_play)),
      ),
    );
  }
}