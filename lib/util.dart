class BotUtil {
  static const String botToken =
      '6899449335:AAGCuRPq0IapnSI5jP-KtJFOHSlcfEHU9yI';
}

class WebSocketBinance {
  static const String wsUrl = 'wss://ws-api.binance.com:443/ws-api/v3';

  String wsIndexUrl(String currencyPair) {
    return 'wss://nbstream.binance.com/eoptions/ws/$currencyPair@index';
  }
}
