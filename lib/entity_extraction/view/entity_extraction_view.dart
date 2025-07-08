import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/entity_extraction_cubit.dart';
import '../models/extracted_entity.dart';

class EntityExtractionView extends StatefulWidget {
  const EntityExtractionView({super.key});

  @override
  State<EntityExtractionView> createState() => _EntityExtractionViewState();
}

class _EntityExtractionViewState extends State<EntityExtractionView> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entity Extraction'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _textController.clear();
              context.read<EntityExtractionCubit>().clearResults();
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            _EntityExtractionStatusCard(),
            const SizedBox(height: 16),

            // Input text field
            _InputTextCard(),
            const SizedBox(height: 16),

            // Results section
            _EntityResultsCard(),
          ],
        ),
      ),
    );
  }
}

/// Status card showing entity extraction state
class _EntityExtractionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EntityExtractionCubit, EntityExtractionState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;
        IconData statusIcon;
        bool showLoading = false;

        if (state.isLoading) {
          statusText = 'Extracting entities...';
          statusColor = Colors.orange;
          statusIcon = Icons.psychology;
          showLoading = true;
        } else if (state.entityExtractionDataState.isFailure) {
          statusText = state.error!;
          statusColor = Colors.red;
          statusIcon = Icons.error;
        } else if (state.entities.isNotEmpty) {
          statusText = 'Found ${state.entities.length} entities';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
        } else if (state.inputText.isNotEmpty) {
          statusText = 'No entities found in the text';
          statusColor = Colors.grey;
          statusIcon = Icons.search_off;
        } else {
          statusText = 'Ready to extract entities';
          statusColor = Colors.blue;
          statusIcon = Icons.psychology;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Input text card
class _InputTextCard extends StatefulWidget {
  @override
  State<_InputTextCard> createState() => _InputTextCardState();
}

class _InputTextCardState extends State<_InputTextCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _extractEntities() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<EntityExtractionCubit>().extractEntities(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Text',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText:
                    'Enter text to extract entities (e.g., "Meet me at 1600 Amphitheatre Parkway, Mountain View, CA at 2:00 PM tomorrow")',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
              minLines: 3,
              onSubmitted: (_) => _extractEntities(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _extractEntities,
                icon: const Icon(Icons.psychology),
                label: const Text('Extract Entities'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entity results card
class _EntityResultsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EntityExtractionCubit, EntityExtractionState>(
      builder: (context, state) {
        if (state.entities.isEmpty && !state.isLoading) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extracted Entities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.entities.isNotEmpty)
                  ...state.entities.map(
                    (entity) => _EntityTile(entity: entity),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual entity tile
class _EntityTile extends StatelessWidget {
  final ExtractedEntity entity;

  const _EntityTile({required this.entity});

  Color _getEntityColor(String type) {
    switch (type.toLowerCase()) {
      case 'address':
        return Colors.blue;
      case 'date/time':
        return Colors.green;
      case 'email':
        return Colors.orange;
      case 'phone number':
        return Colors.purple;
      case 'url':
        return Colors.indigo;
      case 'money':
        return Colors.teal;
      case 'flight number':
        return Colors.red;
      case 'payment card':
        return Colors.brown;
      case 'tracking number':
        return Colors.pink;
      case 'isbn':
        return Colors.cyan;
      case 'iban':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getEntityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'address':
        return Icons.location_on;
      case 'date/time':
        return Icons.access_time;
      case 'email':
        return Icons.email;
      case 'phone number':
        return Icons.phone;
      case 'url':
        return Icons.link;
      case 'money':
        return Icons.attach_money;
      case 'flight number':
        return Icons.flight;
      case 'payment card':
        return Icons.credit_card;
      case 'tracking number':
        return Icons.local_shipping;
      case 'isbn':
        return Icons.book;
      case 'iban':
        return Icons.account_balance;
      default:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getEntityColor(entity.type);
    final icon = _getEntityIcon(entity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          entity.text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${entity.type}',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            Text(
              'Position: ${entity.startIndex} - ${entity.endIndex}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: entity.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied "${entity.text}" to clipboard'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Copy to clipboard',
        ),
        tileColor: color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
