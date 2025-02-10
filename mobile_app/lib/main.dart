import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/pages/home.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/pages/register.dart';
import 'package:mobile_app/pages/controller_dashboard.dart';
import 'package:mobile_app/util/routes.dart';
import 'package:mobile_app/pages/callback.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_app/util/url/strategy.dart';


void main() {
  if (kIsWeb) {
    Strategy.getStrategyFactory().configure();
  }
  runApp(MyApp());
}


final GoRouter router = GoRouter(
  initialLocation: RouteURLs.HOME,
  redirect: (context, state) async {
    String userId = await BaseStorage.getStorageFactory().getUserId();

    // Check if the user is logged in
    if (userId.isNotEmpty) {
      // Redirect to home if already logged in and trying to visit login or register page
      if (state.uri.path == RouteURLs.LOGIN || state.uri.path == RouteURLs.REGISTER) {
        return RouteURLs.HOME;
      }

      // Check if the path is a controller route with an ID
      if (state.uri.path.startsWith(RouteURLs.CONTROLLER)) {
        final controllerId = state.uri.pathSegments.last;
        List<String> controllers = await BaseStorage.getStorageFactory().getControllerList();
        print('Controller ID: $controllerId');

        // Check if the controller ID exists in the list of controllers
        if (controllers.contains(controllerId)) {
          return null;  // Valid controller, no redirection needed
        } else {
          return RouteURLs.HOME;  // Invalid controller ID, redirect to home
        }
      }
      return null;
    }

    // If the user is not logged in and trying to access a protected route, redirect to login
    return state.uri.path == RouteURLs.LOGIN || state.uri.path == RouteURLs.REGISTER ? null : RouteURLs.LOGIN;
  },
  routes: <RouteBase>[
    GoRoute(
      path: RouteURLs.LOGIN,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteURLs.REGISTER,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteURLs.HOME,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(path: '/auth/callback',
      builder: (context, state) => CallbackScreen(),
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