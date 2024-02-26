import 'package:web_socket_channel/web_socket_channel.dart';

class TradingPair {
  String name;
  double? upperLimit;
  double? lowerLimit;
  WebSocketChannel? webSocketChannel;

  TradingPair(this.name,
      {this.upperLimit, this.webSocketChannel, this.lowerLimit});

  factory TradingPair.createFromVariables(
      String? userIndexChoice,
      String? upperLimit,
      String? lowerLimit,
      WebSocketChannel? webSocketChannel) {
    double? upperLimitValue =
        upperLimit != null ? double.tryParse(upperLimit) : null;
    double? lowerLimitValue =
        lowerLimit != null ? double.tryParse(lowerLimit) : null;

    return TradingPair(
      userIndexChoice ?? '',
      upperLimit: upperLimitValue,
      lowerLimit: lowerLimitValue,
      webSocketChannel: webSocketChannel,
    );
  }
}
