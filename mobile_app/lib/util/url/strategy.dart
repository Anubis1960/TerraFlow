import 'package:mobile_app/util/url/strategy_stub.dart'
  if (dart.library.html) 'package:mobile_app/util/url/web_strategy.dart';


/// A base class for URL strategies that defines the interface for configuring URL handling.
abstract class Strategy{

  /// Returns the strategy for the current platform.
  void configure();

  /// Returns the appropriate URL strategy based on the platform.
  static Strategy getStrategyFactory() => getStrategy();
}