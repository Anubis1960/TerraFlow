import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_app/util/url/strategy.dart';

/// A strategy for configuring URL handling in web applications.
class WebStrategy extends Strategy {

  /// Configures the URL strategy for web applications.
  @override
  void configure() {
    setUrlStrategy(PathUrlStrategy());
  }
}

/// Returns the web URL strategy.
WebStrategy getStrategy() {
  return WebStrategy();
}