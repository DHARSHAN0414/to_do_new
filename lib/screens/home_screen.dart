import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_card.dart';
import '../widgets/input_field.dart';
import '../widgets/app_button.dart';
import '../services/share_service.dart';
import 'task_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ShareService _shareService = ShareService();
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 300) {
      setState(() {
        _visibleCount += 20;
      });
    }
  }

  void _onAddTask(BuildContext context) async {
    final vm = context.read<TaskViewModel>();
    final result = await showDialog<_NewTaskResult>(
      context: context,
      builder: (context) => const _NewTaskDialog(),
    );
    if (result != null && result.title.trim().isNotEmpty) {
      await vm.addTask(title: result.title.trim(), description: result.description?.trim());
    }
  }

  void _onShareTask(BuildContext context, Task task) async {
    final vm = context.read<TaskViewModel>();
    final result = await showDialog<_ShareTaskResult>(
      context: context,
      builder: (context) => _ShareTaskDialog(existing: task.sharedWith),
    );
    if (result != null) {
      if (result.isEmailInvite) {
        await vm.shareTaskWithEmails(task, result.emailAddresses);
      } else {
        await vm.shareTaskWith(task, result.userIds);
      }
    }
  }

  void _onShareTaskExternal(BuildContext context, Task task) async {
    try {
      await _shareService.shareTask(
        taskId: task.id,
        taskTitle: task.title,
        taskDescription: task.description,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isLargeScreen = size.width >= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.background.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Your Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: FilledButton.icon(
                      onPressed: () => _onAddTask(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Add Task',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: 16,
                ),
                sliver: Consumer<TaskViewModel>(
                  builder: (context, vm, _) {
                    final stream = vm.tasksStream;
                    if (stream == null) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isLargeScreen ? 800 : (isTablet ? 600 : double.infinity),
                            ),
                            child: _buildPlaceholder(theme),
                          ),
                        ),
                      );
                    }
                    return StreamBuilder<List<Task>>(
                      stream: stream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isLargeScreen ? 800 : (isTablet ? 600 : double.infinity),
                                ),
                                child: _buildLoadingState(),
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isLargeScreen ? 800 : (isTablet ? 600 : double.infinity),
                                ),
                                child: _buildErrorState(theme),
                              ),
                            ),
                          );
                        }
                        final tasks = snapshot.data ?? const <Task>[];
                        if (tasks.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isLargeScreen ? 800 : (isTablet ? 600 : double.infinity),
                                ),
                                child: _buildEmptyState(theme, isTablet),
                              ),
                            ),
                          );
                        }
                        return _buildTaskListSliver(tasks, vm, isTablet, isLargeScreen);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTaskListSliver(List<Task> tasks, TaskViewModel vm, bool isTablet, bool isLargeScreen) {
    final count = min(_visibleCount, tasks.length);
    
    if (isTablet) {
      // Grid layout for tablets with animations
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= count) {
                return const Center(
                  child: CircularProgressIndicator(),
                ).animate().fadeIn(duration: 300.ms);
              }
              final task = tasks[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: TaskCard(
                      task: task,
                      onToggleCompleted: () => vm.toggleTaskCompletion(task),
                      onShare: () => _onShareTask(context, task),
                      onShareExternal: () => _onShareTaskExternal(context, task),
                      onDelete: () => vm.deleteTask(task.id),
                      onTap: () => _onTaskTap(context, task),
                      isCompact: true,
                    ),
                  ),
                ),
              );
            },
            childCount: count + (count < tasks.length ? 1 : 0),
          ),
        ),
      );
    } else {
      // List layout for phones with animations
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= count) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ).animate().fadeIn(duration: 300.ms);
              }
              final task = tasks[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: task,
                        onToggleCompleted: () => vm.toggleTaskCompletion(task),
                        onShare: () => _onShareTask(context, task),
                        onShareExternal: () => _onShareTaskExternal(context, task),
                        onDelete: () => vm.deleteTask(task.id),
                        onTap: () => _onTaskTap(context, task),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: count + (count < tasks.length ? 1 : 0),
          ),
        ),
      );
    }
  }

  Widget _buildTaskList(List<Task> tasks, TaskViewModel vm, bool isTablet) {
    final count = min(_visibleCount, tasks.length);
    
    if (isTablet) {
      // Grid layout for tablets with animations
      return AnimationLimiter(
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: count + (count < tasks.length ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= count) {
              return const Center(
                child: CircularProgressIndicator(),
              ).animate().fadeIn(duration: 300.ms);
            }
            final task = tasks[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: TaskCard(
                    task: task,
                    onToggleCompleted: () => vm.toggleTaskCompletion(task),
                    onShare: () => _onShareTask(context, task),
                    onShareExternal: () => _onShareTaskExternal(context, task),
                    onDelete: () => vm.deleteTask(task.id),
                    onTap: () => _onTaskTap(context, task),
                    isCompact: true,
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // List layout for phones with animations
      return AnimationLimiter(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: count + (count < tasks.length ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= count) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ).animate().fadeIn(duration: 300.ms);
            }
            final task = tasks[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onToggleCompleted: () => vm.toggleTaskCompletion(task),
                      onShare: () => _onShareTask(context, task),
                      onShareExternal: () => _onShareTaskExternal(context, task),
                      onDelete: () => vm.deleteTask(task.id),
                      onTap: () => _onTaskTap(context, task),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _onTaskTap(BuildContext context, Task task) {
    // Navigate to task details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.login, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Please sign in to view your tasks',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 12),
        Text(
          'Error loading tasks',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Please try again later',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your tasks...',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(ThemeData theme, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 120 : 80,
            height: isTablet ? 120 : 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 60 : 40),
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: isTablet ? 60 : 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No tasks yet',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isTablet 
                ? 'Click the Add Task button to create your first task'
                : 'Tap the Add button to create your first task',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _onAddTask(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Create Task',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }
}


class _NewTaskResult {
  const _NewTaskResult({required this.title, this.description});
  final String title;
  final String? description;
}

class _NewTaskDialog extends StatefulWidget {
  const _NewTaskDialog();

  @override
  State<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<_NewTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputFieldWithLabel(
              label: 'Title',
              controller: _titleController,
              textInputAction: TextInputAction.next,
              isRequired: true,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            InputFieldWithLabel(
              label: 'Description',
              controller: _descController,
              maxLines: 3,
              hintText: 'Optional description',
            ),
          ],
        ),
      ),
      actions: [
        SecondaryButton(onPressed: () => Navigator.pop(context), label: 'Cancel'),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _NewTaskResult(title: _titleController.text, description: _descController.text));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ShareTaskResult {
  const _ShareTaskResult({
    required this.isEmailInvite,
    this.userIds = const [],
    this.emailAddresses = const [],
  });

  final bool isEmailInvite;
  final List<String> userIds;
  final List<String> emailAddresses;
}

class _ShareTaskDialog extends StatefulWidget {
  const _ShareTaskDialog({required this.existing});
  final List<String> existing;

  @override
  State<_ShareTaskDialog> createState() => _ShareTaskDialogState();
}

class _ShareTaskDialogState extends State<_ShareTaskDialog> {
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEmailInvite = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Share Task'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share method selection
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Email'),
                  icon: Icon(Icons.email),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('User ID'),
                  icon: Icon(Icons.person),
                ),
              ],
              selected: {_isEmailInvite},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isEmailInvite = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Input field
            Text(
              _isEmailInvite 
                  ? 'Enter email addresses to invite (comma separated)'
                  : 'Enter user IDs to share with (comma separated)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            InputField(
              controller: _isEmailInvite ? _emailController : _userIdController,
              hintText: _isEmailInvite 
                  ? 'e.g. user1@example.com, user2@example.com'
                  : 'e.g. user1, user2, user3',
              prefixIcon: Icon(_isEmailInvite ? Icons.email : Icons.person),
              keyboardType: _isEmailInvite ? TextInputType.emailAddress : TextInputType.text,
            ),
            
            if (widget.existing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Currently shared with:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.existing
                    .map((e) => Chip(
                          label: Text(e),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ]
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          onPressed: () => Navigator.pop(context),
          label: 'Cancel',
        ),
        FilledButton(
          onPressed: () {
            final raw = (_isEmailInvite ? _emailController : _userIdController).text.trim();
            final items = raw.isEmpty
                ? <String>[]
                : raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
            
            Navigator.pop(
              context,
              _ShareTaskResult(
                isEmailInvite: _isEmailInvite,
                userIds: _isEmailInvite ? [] : items,
                emailAddresses: _isEmailInvite ? items : [],
              ),
            );
          },
          child: Text(_isEmailInvite ? 'Send Invites' : 'Share'),
        ),
      ],
    );
  }
}


