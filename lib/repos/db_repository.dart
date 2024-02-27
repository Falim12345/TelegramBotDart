import 'package:dart_application_1/util.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main(List<String> args) async {
  var db = await Db.create(
      "mongodb+srv://${MongoDb.username}:${MongoDb.password}@cluster0.bmaopus.mongodb.net/DartBot1?retryWrites=true&w=majority&appName=Cluster0");

  await db.open();
  db
      .collection(MongoDb.userCollection)
      .insertOne({'test': 'test1', 'test2': 'test2'});
}
