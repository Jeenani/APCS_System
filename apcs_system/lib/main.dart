import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/constants.dart';
import 'models/task_model.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/edit_task_screen.dart';
import 'screens/search_screen.dart';
import 'screens/task_history_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем ApiClient при запуске приложения
  try {
    await ApiClient.initialize();
  } catch (e) {
    print('Ошибка инициализации ApiClient: $e');
  }

  runApp(const AsutpTasksApp());
}

class AsutpTasksApp extends StatelessWidget {
  const AsutpTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'АСУТП Tasks',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: AppColors.primary,
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
          ),
        ),
        home: const _AuthGate(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case '/create-task':
              return MaterialPageRoute(builder: (_) => const CreateTaskScreen());
            case '/task-detail':
              final taskId = settings.arguments as int;
              return MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: taskId));
            case '/edit-task':
              final task = settings.arguments as TaskModel;
              return MaterialPageRoute(builder: (_) => EditTaskScreen(task: task));
            case '/search':
              return MaterialPageRoute(builder: (_) => const SearchScreen());
            case '/task-history':
              final taskId = settings.arguments as int;
              return MaterialPageRoute(builder: (_) => TaskHistoryScreen(taskId: taskId));
            case '/notification-settings':
              return MaterialPageRoute(builder: (_) => const NotificationSettingsScreen());
            case '/admin/users':
              return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
            case '/admin/categories':
              return MaterialPageRoute(builder: (_) => const AdminCategoriesScreen());
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().tryAutoLogin();
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, size: 64, color: AppColors.primary),
              SizedBox(height: 16),
              Text('АСУТП Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final isAuth = context.watch<AuthProvider>().isAuthenticated;
    return isAuth ? const HomeScreen() : const LoginScreen();
  }
}
