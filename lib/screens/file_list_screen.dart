import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/file_provider.dart';
import '../providers/auth_provider.dart';
import 'file_upload_screen.dart';
import 'file_details_screen.dart';
import 'shared_files_screen.dart';
import 'search_filter_screen.dart';

class FileListScreen extends StatelessWidget {
  const FileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart File Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SharedFilesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
              await context.read<FileProvider>().syncData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync complete!')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Clear All Local Data',
            onPressed: () => _showClearDataDialog(context),
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          final files = provider.files;
          if (files.isEmpty) {
            return const Center(child: Text('No files found. Add some!'));
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                leading: Icon(_getFileIcon(file.type), color: Colors.blue),
                title: Text(file.name),
                subtitle: Text('Type: ${file.type} • v${file.currentVersion}'),
                trailing: file.isShared ? const Icon(Icons.group, color: Colors.green) : null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FileUploadScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will permanently delete all users and files from this browser/device. This proves the data was stored locally.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // 1. Clear JSON Database structure
              await Hive.box('jsonStoreBox').clear();
              // Re-init with empty structure
              final initialData = {'users': [], 'files': []};
              await Hive.box('jsonStoreBox').put('app_database_json', jsonEncode(initialData));
              
              if (context.mounted) {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All local data cleared!')),
                );
              }
            },
            child: const Text('Clear Everything', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'doc':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
