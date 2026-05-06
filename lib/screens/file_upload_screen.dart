import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _type = 'PDF';
  String _description = '';
  String? _selectedFileName;
  bool _isUploading = false;

  final List<String> _types = ['PDF', 'Image', 'Doc', 'Other'];

  // Using native browser picking to avoid plugin errors on Web
  void _pickFileNative() {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = '.pdf,.png,.jpg,.jpeg,.doc,.docx,.txt';
    input.click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        setState(() {
          _selectedFileName = file.name;
          _nameController.text = file.name;
          
          // Detect type
          final name = file.name.toLowerCase();
          if (name.endsWith('.pdf')) _type = 'PDF';
          else if (name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.jpeg')) _type = 'Image';
          else if (name.endsWith('.doc') || name.endsWith('.docx') || name.endsWith('.txt')) _type = 'Doc';
          else _type = 'Other';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New File')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              InkWell(
                onTap: _pickFileNative,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.file_present, size: 48, color: Colors.blue.shade700),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName == null ? 'Click to Select a Local File' : 'Selected: $_selectedFileName',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'File Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) => _description = value,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isUploading = true);
                      
                      await context.read<FileProvider>().addFile(
                        _nameController.text, 
                        _type, 
                        _description
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: Colors.green, content: Text('File successfully added to JSON database!')),
                        );
                      }
                    }
                  },
                  child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirm & Update database.json', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
