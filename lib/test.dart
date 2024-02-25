import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  final lowerLimit = 51729; // Нижний предел
  final upperLimit = 51731; // Верхний предел

  final channel = WebSocketChannel.connect(Uri.parse(
      'wss://stream.binance.com:9443/ws/btcusdt@avgPrice')); // Замените 'wss://your_websocket_url' на ваш URL WebSocket
  // Подписываемся на события сокета
  final stream = channel.stream.listen((message) {
    final data = jsonDecode(message);
    print(message);
    final avgPrice = double.parse(data['w'].toString());

    // Проверяем, если средняя цена выходит за пределы
    if (avgPrice < lowerLimit) {
      print('Средняя цена пересекла нижний предел. Средняя цена: $avgPrice');
      channel.sink.close(); // Закрываем соединение
    } else if (avgPrice > upperLimit) {
      print('Средняя цена пересекла верхний предел. Средняя цена: $avgPrice');
      channel.sink.close(); // Закрываем соединение
    }
  });

  // Обработка ошибок
  stream.onError((error) {
    print('Произошла ошибка: $error');
  });

  // Пример отправки сообщения на сервер (если необходимо)
  // channel.sink.add('Пример сообщения');
}
