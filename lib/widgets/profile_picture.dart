import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final String? imageUrl;

  const ProfilePicture({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open image picker (camera/gallery)
      },
      child: ClipOval(
        child: Container(
          width: 120,
          height: 120,
          color: Colors.grey.shade200,
          child: imageUrl != null
              ? Image.network(imageUrl!, fit: BoxFit.cover)
              : const Icon(Icons.person, size: 64),
        ),
      ),
    );
  }
}