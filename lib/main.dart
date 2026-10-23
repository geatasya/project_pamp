import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/event/data/event_remote_datasource.dart';
import 'features/event/data/event_repository_impl.dart';
import 'features/event/domain/usecases/event_usecases.dart';
import 'features/event/presentation/event_provider.dart';
import 'features/home/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Supabase.initialize(
      url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);

  final client = Supabase.instance.client;
  final authRepo = AuthRepositoryImpl(client);
  final eventRepo = EventRepositoryImpl(EventRemoteDataSource(client));

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AuthProvider(
              authRepo, Login(authRepo), Register(authRepo), Logout(authRepo))),
      ChangeNotifierProvider(
          create: (_) => EventProvider(
                GetEvents(eventRepo),
                AddEvent(eventRepo),
                UpdateEvent(eventRepo),
                DeleteEvent(eventRepo),
                UploadPoster(eventRepo),
              )),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    return MaterialApp(
      title: 'Event-Tix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: loggedIn ? const MainShell() : const LoginPage(),
    );
  }
}
