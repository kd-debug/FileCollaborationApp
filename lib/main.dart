import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/file_provider.dart';
import 'providers/auth_provider.dart';
import 'services/database_service.dart';
import 'screens/file_list_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Hive.initFlutter();
    
    final dbService = DatabaseService();
    await dbService.init();

    final fileProvider = FileProvider();
    await fileProvider.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProxyProvider<AuthProvider, FileProvider>(
            create: (_) => fileProvider,
            update: (_, auth, file) {
              file!.setCurrentUser(auth.currentUser?.username);
              return file;
            },
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initialization Error: $e')),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart File Sharing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const FileListScreen() : const LoginScreen();
        },
      ),
    );
  }
}
