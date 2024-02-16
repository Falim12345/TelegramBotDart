import 'package:dart_application_1/util.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final dio = Dio();

Future<Set<String>> getAllTradingPairs() async {
  final response = await dio.get('https://api.binance.com/api/v3/ticker/price');

  if (response.statusCode == 200) {
    final List<dynamic> tickers = response.data;
    final Set<String> tradingPairs = {};

    for (var tickerData in tickers) {
      final String symbol = tickerData['symbol'];
      tradingPairs.add(symbol);
    }

    return tradingPairs;
  } else {
    print('Failed to fetch data, status code: ${response.statusCode}');
    return {};
  }
}

Future<List<String>> getAllCoins() async {
  try {
    final response =
        await Dio().get('https://api.binance.com/api/v3/exchangeInfo');
    final data = response.data;

    Set<String> allCoins = {};
    for (var symbol in data['symbols']) {
      allCoins.add(symbol['baseAsset']);
      allCoins.add(symbol['quoteAsset']);
    }

    return allCoins.toList();
  } catch (e) {
    print('Error fetching coins: $e');
    return [];
  }
}

class GetIndexBinance {
  // Метод для получения WebSocketChannel
  Future<WebSocketChannel> getWebSocketChannel(String coin) async {
    final wsUrl = Uri.parse(WebSocketBinance().wsIndexUrl(coin));
    final channel = WebSocketChannel.connect(wsUrl);
    await channel.ready;

    return channel;
  }
}
// class GetIndexBinance {
//   Future getIndex(coin) async {
//     final wsUrl = Uri.parse(WebSocketBinance().wsIndexUrl(coin));
//     final channel = WebSocketChannel.connect(wsUrl);
//     await channel.ready;

//     channel.stream.listen(
//       (message) {
//         // Этот обработчик вызывается при получении сообщения
//         print('Received message: $message');
//       },
//       onDone: () {
//         // Этот обработчик вызывается, когда соединение закрывается
//         print('Connection closed');
//       },
//       onError: (error) {
//         // Этот обработчик вызывается в случае ошибки
//         print('Error: $error');
//       },
//       cancelOnError:
//           true, // Позволяет автоматически закрыть соединение при возникновении ошибки
//     );
//   }
// }


// class ConnectionManager {
//   final Map<String, WebSocketChannel> _connections = {};

//   void addConnection(String coin, WebSocketChannel channel) {
//     _connections[coin] = channel;
//   }

//   WebSocketChannel? getConnection(String coin) {
//     return _connections[coin];
//   }

//   void removeConnection(String coin) {
//     _connections.remove(coin);
//   }

//   void closeAllConnections() {
//     for (var channel in _connections.values) {
//       channel.sink.close();
//     }
//     _connections.clear();
//   }
// }


// void main(List<String> args) {
//   getIndex('BTCUSDT');
//   getIndex('ETHUSDT');
// }
