class Routes {
  static const String HOME = '/home';
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';
  static const String DEVICE = '/device';
  static const String OTHER = '*';
  static const String CALLBACK = '/auth/callback';
  static const String DISEASE_CHECK = '/home/disease-check';
}

class Server {
  static final String WEB_SOCKET_URL = 'ws://192.168.100.47:5000';
  static final String MOBILE_SOCKET_URL = 'ws://192.168.100.47:5000';
  static final String WEB_BASE_URL = 'http://192.168.100.47:5000';
  static final String MOBILE_BASE_URL = 'http://192.168.100.47:5000';

  static const String LOGIN_REST_URL = '/login';
  static const String REGISTER_REST_URL = '/register';
  static const String DEVICE_REST_URL = '/device';
  static const String USER_REST_URL = '/user';
}