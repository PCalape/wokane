import 'package:flutter/material.dart';
import 'package:expense_tracker/services/api_service.dart';

class ExpenseItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final String? receiptImage;

  const ExpenseItem({
    Key? key,
    required this.title,
    required this.amount,
    required this.date,
    this.receiptImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing:
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
      leading: receiptImage != null
          ? SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  '${ApiService.baseUrl}${receiptImage!}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 24),
                  ),
                ),
              ),
            )
          : null,
      onTap: receiptImage != null
          ? () {
              // Show full image when tapped
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: Text(title),
                        centerTitle: true,
                        automaticallyImplyLeading: false,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          '${ApiService.baseUrl}${receiptImage!}',
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                                child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ));
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Failed to load image'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          : null,
    );
  }
}
