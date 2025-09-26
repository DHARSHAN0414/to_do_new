import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompleted,
    required this.onShare,
    required this.onShareExternal,
    required this.onDelete,
    this.onTap,
    this.isCompact = false,
  });

  final Task task;
  final VoidCallback onToggleCompleted;
  final VoidCallback onShare;
  final VoidCallback onShareExternal;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;
    final isLargeScreen = screenSize.width >= 900;

    return Dismissible(
      key: ValueKey(task.id),
      background: _buildDismissBackground(theme),
      secondaryBackground: _buildDismissBackground(theme),
      confirmDismiss: (direction) => _showDeleteConfirmation(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.symmetric(
          vertical: isTablet ? 6 : 4,
          horizontal: isLargeScreen ? 0 : 0,
        ),
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: _buildCardContent(context, theme, isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(ThemeData theme) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.delete_outline,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        _buildCheckbox(theme),
        SizedBox(width: isTablet ? 12 : 8),
        
        // Task content
        Expanded(
          child: _buildTaskContent(context, theme, isTablet),
        ),
        
        // Action buttons
        _buildActionButtons(context, theme, isTablet),
      ],
    );
  }

  Widget _buildCheckbox(ThemeData theme) {
    return Checkbox(
      value: task.completed,
      onChanged: (_) => onToggleCompleted(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      side: BorderSide(
        color: theme.colorScheme.outline,
        width: 1.5,
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          task.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed 
                ? theme.colorScheme.onSurfaceVariant 
                : theme.colorScheme.onSurface,
          ),
          maxLines: isTablet ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Description
        if ((task.description ?? '').isNotEmpty) ...[
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            task.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: isTablet ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Metadata
        if (isTablet) ...[
          SizedBox(height: 8),
          _buildMetadata(theme),
        ],
      ],
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(task.updatedAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (task.sharedWith.isNotEmpty) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.people,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${task.sharedWith.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, bool isTablet) {
    return PopupMenuButton<String>(
      tooltip: 'Share',
      icon: const Icon(Icons.ios_share_outlined),
      onSelected: (value) {
        switch (value) {
          case 'invite':
            onShare();
            break;
          case 'external':
            onShareExternal();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'invite',
          child: Row(
            children: [
              Icon(Icons.person_add, size: 20),
              SizedBox(width: 8),
              Text('Invite by Email'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'external',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Share via App'),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
