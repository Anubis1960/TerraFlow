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
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}