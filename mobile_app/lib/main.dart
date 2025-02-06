import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/pages/home.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/pages/register.dart';
import 'package:mobile_app/pages/controller_dashboard.dart';
import 'package:mobile_app/util/routes.dart';


void main() {
  runApp(const MyApp());
}


final GoRouter router = GoRouter(
  initialLocation: RouteURLs.HOME,
  redirect: (context, state) async {
    String userId = await BaseStorage.getStorageFactory().getUserId();
    if (userId.isNotEmpty) {
      if (state.uri.path == RouteURLs.LOGIN || state.uri.path == RouteURLs.REGISTER) {
        return RouteURLs.HOME;
      }
      return null;
    }
    return state.uri.path == RouteURLs.LOGIN || state.uri.path == RouteURLs.REGISTER ? null : RouteURLs.LOGIN;
  },
  routes: <RouteBase>[
    GoRoute(
      path: RouteURLs.LOGIN,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RouteURLs.REGISTER,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: RouteURLs.HOME,
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '${RouteURLs.CONTROLLER}/:id',
      builder: (context, state) {
        final controllerId = state.pathParameters["id"]!;
        return ControllerDashBoard(controllerId: controllerId);
      },
    ),
    GoRoute(
      path: RouteURLs.OTHER,
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Page not found')),
      ),
    ),
  ],
);


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Auth App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}