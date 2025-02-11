
import 'package:flutter/material.dart';
import 'package:mobile_app/pages/login.dart';
import 'package:mobile_app/util/storage/base_storage.dart';
import 'package:mobile_app/pages/home.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/pages/register.dart';
import 'package:mobile_app/pages/controller_dashboard.dart';
import 'package:mobile_app/util/constants.dart';
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
  initialLocation: Routes.LOGIN,
  redirect: (context, state) async {
    final token = await BaseStorage.getStorageFactory().getToken();
    if (state.uri.path.startsWith(Routes.CALLBACK)) {
      return null;
    }

    // Check if the user is logged in
    if (token.isNotEmpty) {
      // Redirect to home if already logged in and trying to visit login or register page
      if (state.uri.path == Routes.LOGIN || state.uri.path == Routes.REGISTER) {
        return Routes.HOME;
      }

      // Check if the path is a controller route with an ID
      if (state.uri.path.startsWith(Routes.CONTROLLER)) {
        final controllerId = state.uri.pathSegments.last;
        List<String> controllers = await BaseStorage.getStorageFactory().getControllerList();

        // Check if the controller ID exists in the list of controllers
        if (controllers.contains(controllerId)) {
          return null;  // Valid controller, no redirection needed
        } else {
          return Routes.HOME;  // Invalid controller ID, redirect to home
        }
      }
      return null;
    }

    // If the user is not logged in and trying to access a protected route, redirect to login
    return state.uri.path == Routes.LOGIN || state.uri.path == Routes.REGISTER ? null : Routes.LOGIN;
  },
  routes: <RouteBase>[
    GoRoute(
      path: Routes.LOGIN,
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: Routes.REGISTER,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: Routes.HOME,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.CALLBACK,
      builder: (context, state) => CallbackScreen(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '${Routes.CONTROLLER}/:id',
      builder: (context, state) {
        final controllerId = state.pathParameters["id"]!;
        return ControllerDashBoard(controllerId: controllerId);
      },
    ),
    GoRoute(
      path: Routes.OTHER,
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
      title: 'Sprinkly',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}