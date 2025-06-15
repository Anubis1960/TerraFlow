
import 'package:mobile_app/util/url/strategy.dart';

/// A stub implementation of the URL strategy for unsupported platforms.
Strategy getStrategy(){

  /// Returns the appropriate URL strategy based on the platform.
  throw UnsupportedError("Platform not supported");
}