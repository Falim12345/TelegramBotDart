class BotUtil {
  static const String botToken =
      '6899449335:AAGCuRPq0IapnSI5jP-KtJFOHSlcfEHU9yI';
}

class WebSocketBinance {
  static const String wsUrl = 'wss://stream.binance.com:9443/ws/@avgPrice';

  String wsIndexUrl(String currencyPair) {
    return 'wss://stream.binance.com:9443/ws/$currencyPair@avgPrice';
  }
}

class MongoDb {
  static String password = 'GJamiplAsUsU5fKG';
  static String username = 'pal2323zet';
  static String userCollection = 'UserHistory';

  String url() {
    return 'mongodb+srv://${MongoDb.username}:${MongoDb.password}@cluster0.bmaopus.mongodb.net/DartBot1?retryWrites=true&w=majority&appName=Cluster0';
  }
}
