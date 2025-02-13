import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mobile_app/util/url/strategy.dart';

class WebStrategy extends Strategy {
  @override
  void configure() {
    setUrlStrategy(PathUrlStrategy());
  }
}

WebStrategy getStrategy() {
  return WebStrategy();
}