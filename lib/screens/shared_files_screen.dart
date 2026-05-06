import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import 'file_details_screen.dart';

class SharedFilesScreen extends StatelessWidget {
  const SharedFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Files')),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          final shared = provider.sharedFiles;
          if (shared.isEmpty) {
            return const Center(child: Text('No shared files.'));
          }
          return ListView.builder(
            itemCount: shared.length,
            itemBuilder: (context, index) {
              final file = shared[index];
              return ListTile(
                leading: const Icon(Icons.group, color: Colors.green),
                title: Text(file.name),
                subtitle: Text('v${file.currentVersion} • ${file.type}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FileDetailsScreen(fileId: file.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
