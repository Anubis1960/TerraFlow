
/// Constants for application routes
class Routes {
  static const String HOME = '/home';
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';
  static const String DEVICE = '/device';
  static const String OTHER = '*';
  static const String CALLBACK = '/auth/callback';
  static const String DISEASE_CHECK = '/home/disease-check';
}

/// Constants for server URLs and REST endpoints
class Server {
  static const String WEB_SOCKET_URL = 'ws://localhost:5000';
  static const String MOBILE_SOCKET_URL = 'ws://10.0.2.2:5000';
  static const String WEB_BASE_URL = 'http://localhost:5000';
  static const String MOBILE_BASE_URL = 'http://10.0.2.2:5000';

  static const String LOGIN_REST_URL = '/login';
  static const String REGISTER_REST_URL = '/register';
  static const String DEVICE_REST_URL = '/device';
  static const String USER_REST_URL = '/user';
}