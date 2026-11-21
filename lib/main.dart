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

import 'features/event_transaction/data/datasources/event_transaction_remote_datasource.dart';
import 'features/event_transaction/data/repositories/event_transaction_repository_impl.dart';
import 'features/event_transaction/domain/usecases/event_transaction_usecases.dart';
import 'features/event_transaction/presentation/providers/event_transaction_provider.dart';

import 'features/savings/data/datasources/savings_remote_datasource.dart';
import 'features/savings/data/repositories/savings_repository_impl.dart';
import 'features/savings/domain/usecases/savings_usecases.dart';
import 'features/savings/presentation/providers/savings_provider.dart';

import 'features/home/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  final client = Supabase.instance.client;

  // 1. Feature Auth & Core
  final authRepo = AuthRepositoryImpl(client);

  // 2. Feature 1: List Event Konser
  final eventRepo = EventRepositoryImpl(
    EventRemoteDataSource(client),
  );

  // 3. Feature 2: Transaksi Event
  final eventTxRepo = EventTransactionRepositoryImpl(
    EventTransactionRemoteDataSource(client),
  );

  // 4. Feature 3: Savings Pocket
  final savingsRepo = SavingsRepositoryImpl(
    SavingsRemoteDataSource(client),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepo,
            Login(authRepo),
            Register(authRepo),
            Logout(authRepo),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(
            GetEvents(eventRepo),
            AddEvent(eventRepo),
            UpdateEvent(eventRepo),
            DeleteEvent(eventRepo),
            UploadPoster(eventRepo),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EventTransactionProvider(
            getEligibleEvents: GetEligibleEvents(eventTxRepo),
            getAvailablePockets: GetAvailablePockets(eventTxRepo),
            getEventTransactions: GetEventTransactions(eventTxRepo),
            addEventTransaction: AddEventTransaction(eventTxRepo),
            updateEventTransaction: UpdateEventTransaction(eventTxRepo),
            deleteEventTransaction: DeleteEventTransaction(eventTxRepo),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SavingsProvider(
            getPockets: GetSavingsPockets(savingsRepo),
            getTransactions: GetPocketTransactions(savingsRepo),
            createPocket: CreatePocket(savingsRepo),
            updatePocket: UpdatePocket(savingsRepo),
            deletePocket: DeletePocket(savingsRepo),
            addTransaction: AddPocketTransaction(savingsRepo),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
