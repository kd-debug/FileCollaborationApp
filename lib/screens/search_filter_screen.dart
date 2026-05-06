import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import 'file_details_screen.dart';

class SearchFilterScreen extends StatelessWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => context.read<FileProvider>().setSearchQuery(value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Type: '),
                Consumer<FileProvider>(
                  builder: (context, provider, _) => DropdownButton<String>(
                    value: provider.selectedType,
                    items: ['All', 'PDF', 'Image', 'Doc', 'Other']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (value) => provider.setSelectedType(value!),
                  ),
                ),
                const Spacer(),
                const Text('Only Shared: '),
                Consumer<FileProvider>(
                  builder: (context, provider, _) => Switch(
                    value: provider.showOnlyShared,
                    onChanged: (value) => provider.toggleOnlyShared(value),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Consumer<FileProvider>(
              builder: (context, provider, _) {
                final files = provider.files;
                if (files.isEmpty) {
                  return const Center(child: Text('No results.'));
                }
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      title: Text(file.name),
                      subtitle: Text(file.type),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FileDetailsScreen(fileId: file.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
