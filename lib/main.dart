import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/task_viewmodel.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shared_task_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(CollabTodoApp(prefs: prefs));
}

class CollabTodoApp extends StatefulWidget {
  const CollabTodoApp({
    super.key,
    required this.prefs,
  });

  final SharedPreferences prefs;

  @override
  State<CollabTodoApp> createState() => _CollabTodoAppState();
}

class _CollabTodoAppState extends State<CollabTodoApp> {
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  String? _initialLink;
  String? _pendingTaskId;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    // Handle app links while the app is already started - be it in
    // the foreground or in the background.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri.toString());
      },
      onError: (err) {
        // Handle exception by warning the user their action did not succeed
        debugPrint('Link error: $err');
      },
    );

    // Handle app links while the app is in the background
    // or not yet started.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _initialLink = initialUri.toString();
        _handleIncomingLink(_initialLink!);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }
  }

  void _handleIncomingLink(String link) {
    debugPrint('Received link: $link');
    
    // Parse the link to extract task ID
    final uri = Uri.parse(link);
    
    // Handle custom URL scheme: collabtodo://task/{taskId}
    if (uri.scheme == 'collabtodo' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'task') {
      final taskId = uri.pathSegments[1];
      setState(() {
        _pendingTaskId = taskId;
      });
    }
    // Handle web URLs with hash fragments: http://localhost:8080/#/task/{taskId}
    else if ((uri.scheme == 'http' || uri.scheme == 'https') && 
             (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host.contains('collabtodo')) &&
             uri.fragment.isNotEmpty) {
      final fragment = uri.fragment;
      if (fragment.startsWith('/task/') || fragment.startsWith('/shared-task/')) {
        final taskId = fragment.split('/').last;
        setState(() {
          _pendingTaskId = taskId;
        });
      }
    }
    // Handle web URLs with path segments: http://localhost:8080/task/{taskId}
    else if ((uri.scheme == 'http' || uri.scheme == 'https') && 
             (uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host.contains('collabtodo')) &&
             uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'task') {
      final taskId = uri.pathSegments[1];
      setState(() {
        _pendingTaskId = taskId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(prefs: widget.prefs),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, TaskViewModel>(
          create: (_) => TaskViewModel(),
          update: (_, authViewModel, taskViewModel) {
            taskViewModel ??= TaskViewModel();
            if (authViewModel.isSignedIn && authViewModel.currentUser != null) {
              taskViewModel.initialize(authViewModel.currentUser!.uid);
            }
            return taskViewModel;
          },
        ),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return MaterialApp(
            title: 'Collab Todo',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: authViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _buildHome(authViewModel),
            routes: {
              '/signin': (context) => const SignInScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/shared-task': (context) => SharedTaskScreen(
                taskId: _pendingTaskId ?? '',
              ),
            },
            onGenerateRoute: (settings) {
              if (settings.name?.startsWith('/shared-task/') == true) {
                final taskId = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (context) => SharedTaskScreen(taskId: taskId),
                );
              }
              return null;
            },
            // Handle web URL fragments
            onUnknownRoute: (settings) {
              final uri = Uri.tryParse(settings.name ?? '');
              if (uri != null && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'task') {
                final taskId = uri.pathSegments[1];
                return MaterialPageRoute(
                  builder: (context) => SharedTaskScreen(taskId: taskId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthViewModel authViewModel) {
    // If there's a pending task ID from a deep link, show the shared task screen
    if (_pendingTaskId != null) {
      return SharedTaskScreen(taskId: _pendingTaskId!);
    }
    
    if (authViewModel.isSignedIn) {
      return const HomeScreen();
    } else {
      return const SignInScreen();
    }
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        brightness: Brightness.light,
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        tertiary: const Color(0xFFf093fb),
        surface: Colors.white,
        background: const Color(0xFFf8fafc),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade800,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withOpacity(0.8),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF667eea),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: Colors.grey.shade500,
        ),
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFf8fafc),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.8),
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        brightness: Brightness.dark,
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        tertiary: const Color(0xFFf093fb),
        surface: const Color(0xFF1e1e2e),
        background: const Color(0xFF0f0f23),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade200,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade200,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: const Color(0xFF1e1e2e).withOpacity(0.8),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF667eea),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF2d2d44),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.inter(
          color: Colors.grey.shade400,
        ),
        labelStyle: GoogleFonts.inter(
          color: Colors.grey.shade300,
          fontWeight: FontWeight.w500,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0f0f23),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1e1e2e).withOpacity(0.8),
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}