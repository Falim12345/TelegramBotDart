import 'package:web_socket_channel/web_socket_channel.dart';

class TradingPair {
  String name;
  double? upperLimit;
  double? lowerLimit;
  WebSocketChannel? webSocketChannel;

  TradingPair(this.name,
      {this.upperLimit, this.webSocketChannel, this.lowerLimit});

  // Фабричный метод для создания объекта TradingPair из переменных и помещения его в Map
  factory TradingPair.createFromVariables(
      String? userIndexChoice,
      String? upperLimit,
      String? lowerLimit,
      WebSocketChannel? webSocketChannel) {
    // Преобразование строковых представлений пределов в числа
    double? upperLimitValue =
        upperLimit != null ? double.tryParse(upperLimit) : null;
    double? lowerLimitValue =
        lowerLimit != null ? double.tryParse(lowerLimit) : null;

    // Создание объекта TradingPair и возвращение его
    return TradingPair(
      userIndexChoice ??
          '', // Если userIndexChoice равно null, то используется пустая строка
      upperLimit: upperLimitValue,
      lowerLimit: lowerLimitValue,
      webSocketChannel: webSocketChannel,
    );
  }
}
