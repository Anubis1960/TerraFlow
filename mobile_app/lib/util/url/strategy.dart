import 'package:mobile_app/util/url/strategy_stub.dart'
  if (flutter_web_plugins) 'web_strategy.dart';

abstract class Strategy{
  void configure(){
  }

  static Strategy getStrategyFactory() => getStrategy();
}