import 'package:dart_application_1/util.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbRepository {
  static late Db db;

  static Future<void> connect() async {
    db = await Db.create(MongoDb().url());
    await db.open();
  }

  static Future<void> insertHistory(
    hashId,
    tradingPair,
    upperLimit,
    lowerLimit,
    userIdentifier,
  ) async {
    if (!db.isConnected) {
      await db.open();
      await db.collection(MongoDb.userCollection).insertOne({
        'tradingPair': tradingPair,
        'upperLimit': upperLimit,
        'lowerLimit': lowerLimit,
        'hashId': hashId,
        'userIdentifier': userIdentifier
      });
      await db.close();
    } else {
      await db.collection(MongoDb.userCollection).insertOne({
        'tradingPair': tradingPair,
        'upperLimit': upperLimit,
        'lowerLimit': lowerLimit,
        'hashId': hashId,
        'userIdentifier': userIdentifier
      });
      await db.close();
    }
  }
}
