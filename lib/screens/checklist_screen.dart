import 'package:flutter/material.dart';
import 'package:food_recipes_app/models/checklist.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<Checklist> checklists;
  String? selectedChecklistId;

  @override
  void initState() {
    super.initState();
    checklists = List.from(Checklist.sampleChecklists);
    if (checklists.isNotEmpty) {
      selectedChecklistId = checklists[0].id;
    }
  }

  void _toggleItem(String checklistId, String itemId) {
    setState(() {
      final checklistIndex =
          checklists.indexWhere((c) => c.id == checklistId);
      if (checklistIndex != -1) {
        final itemIndex = checklists[checklistIndex]
            .items
            .indexWhere((item) => item.id == itemId);
        if (itemIndex != -1) {
          final item = checklists[checklistIndex].items[itemIndex];
          checklists[checklistIndex].items[itemIndex] =
              item.copyWith(isChecked: !item.isChecked);
        }
      }
    });
  }

  void _deleteChecklist(String checklistId) {
    setState(() {
      checklists.removeWhere((c) => c.id == checklistId);
      if (selectedChecklistId == checklistId) {
        selectedChecklistId =
            checklists.isNotEmpty ? checklists[0].id : null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checklist deleted')),
    );
  }

  void _addNewChecklist() {
    showDialog(
      context: context,
      builder: (context) => _AddChecklistDialog(
        onAdd: (title) {
          setState(() {
            final newChecklist = Checklist(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              recipeId: '',
              createdAt: DateTime.now(),
              items: [],
            );
            checklists.add(newChecklist);
            selectedChecklistId = newChecklist.id;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/cook-book.png',
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              "FLAVOR FIESTA",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: _addNewChecklist,
              icon: const Icon(Icons.add_circle, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: checklists.isEmpty
          ? _buildEmptyState()
          : Row(
              children: [
                // Checklists List
                SizedBox(
                  width: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: checklists.length,
                      itemBuilder: (context, index) {
                        final checklist = checklists[index];
                        final completedCount = checklist.items
                            .where((item) => item.isChecked)
                            .length;
                        final isSelected =
                            selectedChecklistId == checklist.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedChecklistId = checklist.id;
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.blue[50]
                                : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: Colors.blue,
                                      width: 4,
                                    ),
                                  )
                                : null,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  checklist.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedCount/${checklist.items.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Items List
                Expanded(
                  child: _buildChecklistContent(),
                ),
              ],
            ),
    );
  }

  Widget _buildChecklistContent() {
    final currentChecklist = checklists.firstWhere(
      (c) => c.id == selectedChecklistId,
      orElse: () => checklists.first,
    );

    final completedCount =
        currentChecklist.items.where((item) => item.isChecked).length;
    final totalCount = currentChecklist.items.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    final groupedItems = <String, List<ChecklistItem>>{};
    for (var item in currentChecklist.items) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentChecklist.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                          onTap: () =>
                              _deleteChecklist(currentChecklist.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedCount of $totalCount items completed',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          if (groupedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No items in this checklist',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...groupedItems.entries.map((entry) {
              return _buildCategorySection(
                category: entry.key,
                items: entry.value,
                checklistId: currentChecklist.id,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String category,
    required List<ChecklistItem> items,
    required String checklistId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) {
          return _buildChecklistTile(
            item: item,
            checklistId: checklistId,
          );
        }),
      ],
    );
  }

  Widget _buildChecklistTile({
    required ChecklistItem item,
    required String checklistId,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isChecked ? Colors.green[300]! : Colors.grey[200]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: item.isChecked,
                onChanged: (_) {
                  _toggleItem(checklistId, item.id);
                },
                activeColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: item.isChecked
                            ? Colors.grey[400]
                            : Colors.black87,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Checklists Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new checklist to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewChecklist,
            icon: const Icon(Icons.add),
            label: const Text('Create Checklist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChecklistDialog extends StatefulWidget {
  final Function(String) onAdd;

  const _AddChecklistDialog({required this.onAdd});

  @override
  State<_AddChecklistDialog> createState() => _AddChecklistDialogState();
}

class _AddChecklistDialogState extends State<_AddChecklistDialog> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Checklist'),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          hintText: 'Enter checklist name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onAdd(_titleController.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
