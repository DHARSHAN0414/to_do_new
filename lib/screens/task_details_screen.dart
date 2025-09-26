import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/input_field.dart';
import '../widgets/app_button.dart';
import '../services/share_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late bool _isCompleted;
  late bool _hasChanges;
  
  final _formKey = GlobalKey<FormState>();
  final _shareService = ShareService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _isCompleted = widget.task.completed;
    _hasChanges = false;
    
    _titleController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final hasChanges = _titleController.text != widget.task.title ||
        _descriptionController.text != (widget.task.description ?? '') ||
        _isCompleted != widget.task.completed;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _onCompletedChanged(bool value) {
    setState(() {
      _isCompleted = value;
    });
    _onFieldChanged();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final taskViewModel = context.read<TaskViewModel>();
      
      // Update title if changed
      if (_titleController.text != widget.task.title) {
        await taskViewModel.updateTaskTitle(widget.task, _titleController.text);
      }
      
      // Update description if changed
      if (_descriptionController.text != (widget.task.description ?? '')) {
        await taskViewModel.updateTaskDescription(
          widget.task,
          _descriptionController.text.isEmpty ? null : _descriptionController.text,
        );
      }
      
      // Update completion status if changed
      if (_isCompleted != widget.task.completed) {
        await taskViewModel.toggleTaskCompletion(widget.task);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareTask() async {
    try {
      await _shareService.shareTask(
        taskId: widget.task.id,
        taskTitle: widget.task.title,
        taskDescription: widget.task.description,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share task: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareTaskViaEmail() async {
    final emailController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share via Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter email addresses (comma-separated):'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'user@example.com, user2@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true && emailController.text.isNotEmpty) {
      try {
        final emails = emailController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
            
        await _shareService.shareTaskViaEmail(
          taskId: widget.task.id,
          taskTitle: widget.task.title,
          taskDescription: widget.task.description,
          emailAddresses: emails,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share via email: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Cancel',
          ),
          DangerButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Delete',
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await context.read<TaskViewModel>().deleteTask(widget.task.id);
        
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final isLargeScreen = screenSize.width >= 900;
    final taskViewModel = context.watch<TaskViewModel>();
    final canEdit = taskViewModel.canEditTask(widget.task);
    final isOwner = taskViewModel.ownsTask(widget.task);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Details'),
          centerTitle: !isTablet,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    _shareTask();
                    break;
                  case 'email':
                    _shareTaskViaEmail();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share via App'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 20),
                      SizedBox(width: 8),
                      Text('Share via Email'),
                    ],
                  ),
                ),
              ],
            ),
            if (canEdit && _hasChanges)
              PrimaryButton(
                onPressed: _isLoading ? null : _saveChanges,
                label: 'Save',
                icon: Icons.save,
                size: AppButtonSize.small,
                isLoading: _isLoading,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(theme, isTablet, isLargeScreen, canEdit, isOwner),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isTablet, bool isLargeScreen, bool canEdit, bool isOwner) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 800 : (isTablet ? 600 : double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Status Section
              _buildStatusSection(theme, canEdit, isTablet),
              
              SizedBox(height: isTablet ? 32 : 24),
              
              // Task Content Section
              _buildContentSection(theme, canEdit, isTablet),
              
              SizedBox(height: isTablet ? 32 : 24),
              
              // Task Information Section
              _buildInformationSection(theme, isOwner, isTablet),
              
              SizedBox(height: isTablet ? 40 : 32),
              
              // Action Buttons
              _buildActionButtons(theme, canEdit, isOwner, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, bool canEdit, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          'Task completion status',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'Completed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _isCompleted ? 'This task is done' : 'Mark as completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            value: _isCompleted,
            onChanged: canEdit ? _onCompletedChanged : null,
            secondary: Icon(
              _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 12 : 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(ThemeData theme, bool canEdit, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          'Task title and description',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              InputFieldWithLabel(
                label: 'Title',
                controller: _titleController,
                hintText: 'Enter task title',
                prefixIcon: const Icon(Icons.title),
                textInputAction: TextInputAction.next,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: canEdit,
              ),
              SizedBox(height: isTablet ? 20 : 16),
              InputFieldWithLabel(
                label: 'Description',
                controller: _descriptionController,
                hintText: 'Enter task description (optional)',
                prefixIcon: const Icon(Icons.description),
                maxLines: isTablet ? 5 : 4,
                textInputAction: TextInputAction.done,
                enabled: canEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformationSection(ThemeData theme, bool isOwner, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          'Task metadata',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  'Created',
                  DateFormat('MMM dd, yyyy • hh:mm a').format(widget.task.createdAt),
                  Icons.schedule,
                  isTablet,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                _buildInfoRow(
                  context,
                  'Last Updated',
                  DateFormat('MMM dd, yyyy • hh:mm a').format(widget.task.updatedAt),
                  Icons.update,
                  isTablet,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                _buildInfoRow(
                  context,
                  'Owner',
                  isOwner ? 'You' : 'Shared with you',
                  isOwner ? Icons.person : Icons.people,
                  isTablet,
                ),
                if (widget.task.sharedWith.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 16 : 12),
                  _buildInfoRow(
                    context,
                    'Shared With',
                    '${widget.task.sharedWith.length} user${widget.task.sharedWith.length == 1 ? '' : 's'}',
                    Icons.share,
                    isTablet,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool canEdit, bool isOwner, bool isTablet) {
    if (!canEdit && !isOwner) return const SizedBox.shrink();
    
    return Column(
      children: [
        if (canEdit) ...[
          PrimaryButton(
            onPressed: _hasChanges ? _saveChanges : null,
            label: 'Save Changes',
            icon: Icons.save,
            isFullWidth: true,
            isLoading: _isLoading,
          ),
          SizedBox(height: isTablet ? 16 : 12),
        ],
        
        if (isOwner) ...[
          DangerOutlinedButton(
            onPressed: _isLoading ? null : _deleteTask,
            label: 'Delete Task',
            icon: Icons.delete,
            isFullWidth: true,
            isLoading: _isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: isTablet ? 22 : 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          SecondaryButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Cancel',
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Discard',
          ),
        ],
      ),
    ) ?? false;
  }
}
