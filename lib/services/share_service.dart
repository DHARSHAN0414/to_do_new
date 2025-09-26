import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'task_service.dart';

class ShareService {
  final TaskService _taskService;

  ShareService({TaskService? taskService}) 
      : _taskService = taskService ?? TaskService();

  /// Share a task via email or other platforms
  Future<void> shareTask({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
  }) async {
    try {
      final shareLink = _taskService.generateTaskShareLink(taskId);
      final shareText = _buildShareText(taskTitle, taskDescription, shareLink);
      
      await Share.share(
        shareText,
        subject: 'Shared Task: $taskTitle',
      );
    } catch (e) {
      throw Exception('Failed to share task: $e');
    }
  }

  /// Share a task via email specifically
  Future<void> shareTaskViaEmail({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
    required List<String> emailAddresses,
  }) async {
    try {
      final shareLink = _taskService.generateTaskShareLink(taskId);
      final shareText = _buildShareText(taskTitle, taskDescription, shareLink);
      
      final emailUri = Uri(
        scheme: 'mailto',
        path: emailAddresses.join(','),
        query: _encodeQueryParameters({
          'subject': 'Shared Task: $taskTitle',
          'body': shareText,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to share task via email: $e');
    }
  }

  /// Share a task via SMS
  Future<void> shareTaskViaSMS({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
  }) async {
    try {
      final shareLink = _taskService.generateTaskShareLink(taskId);
      final shareText = _buildShareText(taskTitle, taskDescription, shareLink);
      
      final smsUri = Uri(
        scheme: 'sms',
        query: _encodeQueryParameters({
          'body': shareText,
        }),
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw Exception('Could not launch SMS client');
      }
    } catch (e) {
      throw Exception('Failed to share task via SMS: $e');
    }
  }

  /// Copy task link to clipboard
  Future<void> copyTaskLink(String taskId) async {
    try {
      final shareLink = _taskService.generateTaskShareLink(taskId);
      await Share.share(shareLink);
    } catch (e) {
      throw Exception('Failed to copy task link: $e');
    }
  }

  String _buildShareText(String title, String? description, String shareLink) {
    final buffer = StringBuffer();
    buffer.writeln('📋 Task: $title');
    
    if (description != null && description.isNotEmpty) {
      buffer.writeln('📝 Description: $description');
    }
    
    buffer.writeln();
    buffer.writeln('🔗 View and edit this task:');
    buffer.writeln(shareLink);
    buffer.writeln();
    buffer.writeln('💡 Click the link above to:');
    buffer.writeln('• Open in the Collab Todo app (if installed)');
    buffer.writeln('• View in your web browser as fallback');
    buffer.writeln('• Edit and collaborate in real-time');
    buffer.writeln('• See changes instantly with others');
    buffer.writeln('• No account required for shared tasks');
    
    return buffer.toString();
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
