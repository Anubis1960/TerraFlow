import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_app/pages/login.dart';
import 'package:mobile_app/service/auth_service.dart';

import '../../util/constants.dart';

// 🔁 MOCKS
class MockAuthService extends Mock implements AuthService {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockAuthService mockAuthService;
  late MockGoRouter mockRouter;

  setUp(() {
    mockAuthService = MockAuthService();
    mockRouter = MockGoRouter();

  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all login UI components', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Don’t have an account? Register'), findsOneWidget);
    });

    testWidgets('Navigates on successful login', (WidgetTester tester) async {
      when(mockAuthService.login('user@example.com', 'password123')).thenAnswer((_) async => true);
      when(mockRouter.go(Routes.HOME)).thenAnswer((_) {});

      // Use MaterialApp with GoRouter spy
      final root = buildTestableWidgetWithRouter(LoginScreen(), mockRouter);

      await tester.pumpWidget(root);

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).first, 'user@gmail.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pump();

      verify(mockAuthService.login('user@example.com', 'password123')).called(1);
      verify(mockRouter.go(Routes.HOME)).called(1);
    });

    testWidgets('Shows error on failed login', (WidgetTester tester) async {
      when(mockAuthService.login('wrong@example.com', 'wrongpass')).thenAnswer((_) async => false);

      final root = buildTestableWidgetWithRouter(LoginScreen(), mockRouter);
      await tester.pumpWidget(root);

      // Enter invalid credentials
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.enterText(find.byType(TextField).last, 'wrongpass');

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Login failed. Please try again.'), findsOneWidget);
    });

    testWidgets('Navigates to register screen on register link tap', (WidgetTester tester) async {
      final root = buildTestableWidgetWithRouter(LoginScreen(), mockRouter);
      await tester.pumpWidget(root);

      await tester.tap(find.text('Don’t have an account? Register'));
      await tester.pump();

      verify(mockRouter.go(Routes.REGISTER)).called(1);
    });
  });
}

// Helper to wrap LoginScreen with GoRouter context
Widget buildTestableWidgetWithRouter(Widget widget, GoRouter router) {
  return  MaterialApp.router(
    routerDelegate: router.routerDelegate,
    routeInformationParser: router.routeInformationParser,
    builder: (context, child) {
      return Scaffold(
        body: child,
      );
    },
  );
}

// Fake implementation to inject mock AuthService
class AuthService {
  static late AuthService _instance;

  static void setInstanceForTest(AuthService authService) {
    _instance = authService;
  }

  factory AuthService() => _instance;

  Future<bool> login(String email, String password) async {
    return false; // overridden by mocks
  }

  Future<void> loginWithGoogle(BuildContext context) async {} // overridden by mocks
}