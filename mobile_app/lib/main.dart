import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_app/util/url/strategy.dart';
import 'package:mobile_app/util/router.dart';

void main() {
  if (kIsWeb) {
    Strategy.getStrategyFactory().configure();
  }
  runApp(MyApp());
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TerraFlow',
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF5F5F5), // Light grey background
        colorScheme: ColorScheme.light(primary: Colors.blueGrey).copyWith(
          background: Colors.white,
          surface: Colors.white,
        ),
        // Other theme settings...
      ),
      routerConfig: router,
    );
  }
}