import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../style/admin_style.dart';
import '../service/cloudinary_service.dart';

class DocumentUploadDialog extends StatefulWidget {
  final List<Map<String, String>> initialDocuments;

  const DocumentUploadDialog({super.key, required this.initialDocuments});

  @override
  State<DocumentUploadDialog> createState() => _DocumentUploadDialogState();
}

class _DocumentUploadDialogState extends State<DocumentUploadDialog> {
  late List<Map<String, String>> _docs;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _docs = List<Map<String, String>>.from(widget.initialDocuments);
  }

  /// Pick file and upload to Cloudinary
  Future<void> _pickAndUploadDocument() async {
    try {
      // Step 1: Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      PlatformFile pickedFile = result.files.first;

      // Validate file size (max 10MB)
      if (pickedFile.size > 10 * 1024 * 1024) {
        _showSnackBar('File size should not exceed 10MB', isError: true);
        return;
      }

      // Step 2: Ask for document name
      final documentName = await _showDocumentNameDialog();
      if (documentName == null || documentName.trim().isEmpty) return;

      // Step 3: Upload to Cloudinary
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.3;
      });

      String documentUrl;

      if (kIsWeb) {
        // Web platform
        if (pickedFile.bytes == null) {
          throw Exception('Could not read file data');
        }
        documentUrl = await CloudinaryService.uploadDocument(
          bytes: pickedFile.bytes!,
          fileName: pickedFile.name,
        );
      } else {
        // Mobile platform
        if (pickedFile.path == null) {
          throw Exception('Could not read file path');
        }
        documentUrl = await CloudinaryService.uploadDocument(
          file: File(pickedFile.path!),
          fileName: pickedFile.name,
        );
      }

      setState(() {
        _uploadProgress = 0.8;
      });

      // Step 4: Add to documents list
      setState(() {
        _docs.add({
          'name': documentName.trim(),
          'link': documentUrl,
          'fileName': pickedFile.name,
          'fileSize': _formatFileSize(pickedFile.size),
          'uploadDate': DateTime.now().toIso8601String(),
        });
        _uploadProgress = 1.0;
      });

      _showSnackBar('Document uploaded successfully!');

      // Reset uploading state after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      _showSnackBar('Error uploading document: $e', isError: true);
    }
  }

  /// Show dialog to enter document name
  Future<String?> _showDocumentNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.badge_outlined, color: AdminStyle.primaryColor),
            const SizedBox(width: 8),
            const Text('Document Name'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a name for this document',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g., ID Card, Certificate, Resume',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a document name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: AdminStyle.getPrimaryButtonStyle(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get icon based on file extension
  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get color based on file extension
  Color _getFileColor(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Delete document from list
  void _deleteDocument(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${_docs[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _docs.removeAt(index));
              Navigator.pop(context);
              _showSnackBar('Document deleted');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminStyle.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminStyle.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_open,
                      color: AdminStyle.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Documents',
                          style: AdminStyle.bodyLargeBlack.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload and manage employee documents',
                          style: AdminStyle.bodyMedium.copyWith(
                            color: AdminStyle.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.pop(context, _docs),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Upload Progress
            if (_isUploading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AdminStyle.primaryColor,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AdminStyle.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploading document to Cloudinary...',
                          style: AdminStyle.bodyMedium.copyWith(
                            color: AdminStyle.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Documents List
            Expanded(
              child: _docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No documents added yet',
                            style: AdminStyle.bodyLarge.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Document" to upload',
                            style: AdminStyle.bodyMedium.copyWith(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _docs.length,
                      itemBuilder: (context, index) {
                        final doc = _docs[index];
                        final fileName = doc['fileName'] ?? 'Unknown';
                        final fileColor = _getFileColor(fileName);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: fileColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getFileIcon(fileName),
                                color: fileColor,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              doc['name'] ?? 'Unnamed Document',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (doc['fileSize'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    doc['fileSize']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteDocument(index),
                              tooltip: 'Delete',
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadDocument,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Document'),
                      style: AdminStyle.getSecondaryButtonStyle(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.pop(context, _docs),
                      icon: const Icon(Icons.check, size: 20),
                      label: Text('Done (${_docs.length})'),
                      style: AdminStyle.getPrimaryButtonStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
