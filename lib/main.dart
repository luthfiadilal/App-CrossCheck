import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/monitoring/presentation/bloc/monitoring_bloc.dart';
import 'features/monitoring/presentation/bloc/approval_bloc.dart';

import 'package:crosscheck/features/main/presentation/pages/main_screen.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/main/presentation/pages/splash_page.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Tahan splash screen native agar tidak blank
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckSession()),
        ),
        BlocProvider<MonitoringBloc>(create: (context) => MonitoringBloc()),
        BlocProvider<ApprovalBloc>(create: (context) => ApprovalBloc()),
      ],
      child: MaterialApp(
        title: 'CrossCheck',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashPage(),
      ),
    );
  }
}
