import 'package:mobile_app/util/url/strategy_stub.dart'
  if (dart.library.html) 'package:mobile_app/util/url/web_strategy.dart';

abstract class Strategy{
  void configure();
  static Strategy getStrategyFactory() => getStrategy();
}