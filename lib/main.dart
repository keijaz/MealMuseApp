// import 'package:flutter/material.dart';
// import 'screens/homepage.dart';
// import 'firebase_service.dart';
// // import 'screens/expiring.dart';

// Future<void> main() async {
//   // Ensure Flutter bindings are initialized
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await FirebaseService.initialize();
  
//   runApp(const FigmaLoginLab());
// }

// class FigmaLoginLab extends StatelessWidget {
//  const FigmaLoginLab({super.key});
//  @override
//  Widget build(BuildContext context) {
//  return MaterialApp(
//  debugShowCheckedModeBanner: false,
//  home: HomePage(),
//  );
//  }
// }

// -----------------------------------------


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/homepage.dart';
import 'screens/expiring.dart';
import 'firebase_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Global navigator key for handling navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  bool envLoaded = false;
  bool firebaseInitialized = false;
  
  // Initialize ThemeProvider (load saved preference from SharedPreferences)
  await ThemeProvider().initialize();
  // Initialize LocaleProvider (load saved locale)
  await LocaleProvider().initialize();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    envLoaded = true;
    print('✅ Environment variables loaded successfully');
    
    // Check for essential keys
    final essentialKeys = ['SPOONACULAR_API_KEY'];
    for (final key in essentialKeys) {
      if (dotenv.maybeGet(key) == null) {
        print('⚠️  Essential key missing: $key');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Failed to load .env file: $e');
    print('Stack trace: $stackTrace');
    envLoaded = false;
  }
  
  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    firebaseInitialized = true;
    print('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('❌ Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
    firebaseInitialized = false;
  }
  
  // Log overall initialization status
  print('🚀 App initialization complete:');
  print('   - Environment: ${envLoaded ? "✅" : "❌"}');
  print('   - Firebase: ${firebaseInitialized ? "✅" : "❌"}');
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(context);
      _notificationService.scheduleDailyCheck();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Check for expiring items when app comes to foreground
      _notificationService.onAppResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ValueListenableBuilder so the MaterialApp rebuilds when locale changes
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleProvider().localeNotifier,
      builder: (context, locale, _) {
        final isDark = ThemeProvider().darkModeEnabled;
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          routes: {
            '/expiring': (context) => const ExpiringItemsScreen(),
          },
        );
      },
    );
  }
}
