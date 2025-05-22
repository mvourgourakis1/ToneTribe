import 'package:flutter/material.dart';
import 'models/tribe_model.dart';

class TribePage extends StatelessWidget {
  final Tribe tribe;

  const TribePage({Key? key, required this.tribe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tribe.tribeName),
        actions: [
          if (tribe.isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.push_pin, color: Colors.amber),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (tribe.groupIcon != null && tribe.groupIcon!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    tribe.groupIcon!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              tribe.tribeName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (tribe.description != null && tribe.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  tribe.description!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            // Members Section
            Text(
              'Members (${tribe.members?.length ?? 0})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (tribe.members != null && tribe.members!.isNotEmpty)
              ...tribe.members!.map((member) => ListTile(
                    leading: CircleAvatar(child: Text(member[0].toUpperCase())),
                    title: Text(member),
                  )),
            if (tribe.members == null || tribe.members!.isEmpty)
              const Text('No members yet.'),
            const SizedBox(height: 24),
            // Old Playlists Section (placeholder)
            Text(
              'Old Playlists',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // TODO: Replace with actual playlists
            const Text('No playlists yet.'),
          ],
        ),
      ),
    );
  }
}