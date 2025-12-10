import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../style/view_style.dart';

class DocumentListViewer extends StatelessWidget {
  final List<Map<String, String>> documents;

  const DocumentListViewer({super.key, required this.documents});

  Future<void> _openDocument(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showError(context, 'No document URL available');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context, 'Cannot open this document');
      }
    } catch (e) {
      _showError(context, 'Error opening document: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.description;
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

  Color _getFileColor(String? fileName) {
    if (fileName == null) return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No documents available',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: documents.map((doc) {
        final fileName = doc['fileName'];
        final fileColor = _getFileColor(fileName);
        final fileIcon = _getFileIcon(fileName);

        return InkWell(
          onTap: () => _openDocument(context, doc['link']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ViewStyle.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: fileColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: fileColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fileColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(fileIcon, color: fileColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc['name'] ?? 'Unnamed Document',
                        style: ViewStyle.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (fileName != null) ...[
                        Text(
                          fileName,
                          style: ViewStyle.bodySmall.copyWith(
                            color: ViewStyle.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (doc['fileSize'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          doc['fileSize']!,
                          style: ViewStyle.bodySmall.copyWith(
                            color: ViewStyle.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ViewStyle.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: ViewStyle.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
