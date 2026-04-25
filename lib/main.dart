import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_theme.dart';
import 'services/app_state.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WxStationApp());
}

class WxStationApp extends StatelessWidget {
  const WxStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'WX Station',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const DashboardScreen(),
      ),
    );
  }
}
