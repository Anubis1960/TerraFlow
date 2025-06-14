import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_app/util/url/strategy.dart';

class WebStrategy extends Strategy {
  /// Configures the URL strategy for web applications.
  @override
  void configure() {
    setUrlStrategy(PathUrlStrategy());
  }
}

WebStrategy getStrategy() {
  return WebStrategy();
}