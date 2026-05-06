import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class FileDetailsScreen extends StatelessWidget {
  final String fileId;
  const FileDetailsScreen({super.key, required this.fileId});

  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
        actions: [
          Consumer<FileProvider>(
            builder: (context, provider, _) {
              final file = provider.files.firstWhere((f) => f.id == fileId);
              return IconButton(
                icon: Icon(file.isShared ? Icons.group : Icons.group_add),
                onPressed: () => provider.toggleShare(fileId),
                tooltip: file.isShared ? 'Unshare' : 'Share',
              );
            },
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, _) {
          final file = provider.files.firstWhere((f) => f.id == fileId);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Information', icon: Icons.info_outline),
                Text('Name: ${file.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Type: ${file.type}'),
                Text('Description: ${file.description}'),
                if (file.isShared && file.sharedWith.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Shared with: ${file.sharedWith.join(", ")}', 
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showShareNearbyDialog(context, provider, fileId),
                  icon: const Icon(Icons.near_me),
                  label: const Text('Share via Nearby'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50, 
                    foregroundColor: Colors.green
                  ),
                ),
                const Divider(height: 32),
                
                _SectionHeader(title: 'Versions', icon: Icons.history),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: file.versions.length,
                  itemBuilder: (context, index) {
                    final version = file.versions[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(child: Text('v${version.versionNumber}')),
                      title: Text('Version ${version.versionNumber}'),
                      subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(version.timestamp)),
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUpdateDialog(context, provider, file),
                  icon: const Icon(Icons.update),
                  label: const Text('Upload New Version'),
                ),
                const Divider(height: 32),

                _SectionHeader(title: 'Comments', icon: Icons.comment),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: file.comments.length,
                  itemBuilder: (context, index) {
                    final comment = file.comments[index];
                    return Card(
                      child: ListTile(
                        title: Text(comment.text),
                        subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(comment.timestamp)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(hintText: 'Add a comment...'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          provider.addComment(fileId, commentController.text);
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, FileProvider provider, dynamic file) {
    final nameController = TextEditingController(text: file.name);
    final descController = TextEditingController(text: file.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'New Name')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'New Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.updateFile(file.id, name: nameController.text, description: descController.text);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showShareNearbyDialog(BuildContext context, FileProvider provider, String fileId) async {
    final authProvider = context.read<AuthProvider>();
    final users = await authProvider.getOtherUsers();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_tethering, color: Colors.blue),
            SizedBox(width: 10),
            Text('Registered Users'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: users.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No other registered users found to share with.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.username),
                    trailing: const Icon(Icons.send),
                    onTap: () {
                      provider.shareWithUser(fileId, user.username);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('File shared with ${user.username} locally!')),
                      );
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
