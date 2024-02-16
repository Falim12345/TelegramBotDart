// import 'package:dart_application_1/repos/repository.dart';
// import 'package:dart_application_1/util.dart';
// import 'package:teledart/model.dart';
// import 'package:teledart/teledart.dart';
// import 'package:teledart/telegram.dart';

// void main() async {
//   Set<String> coinPars = await getAllTradingPairs();
//   var getIndex = GetIndexBinance();
//   List<TradingPair> selectedPairs = [];
//   String? userIndexChoice;
//   String? upperLimit;
//   String? lowerLimit;
//   final username = (await Telegram(BotUtil.botToken).getMe()).username;
//   var teledart = TeleDart(BotUtil.botToken, Event(username!));

//   teledart.start();

//   teledart.onCommand('start').listen((event) async {
//     var keyboard = coinPars.map((e) => [KeyboardButton(text: e)]).toList();

//     var replyKeyboard = ReplyKeyboardMarkup(
//         keyboard: keyboard,
//         resizeKeyboard: true,
//         oneTimeKeyboard: true,
//         selective: true);
//     await event.reply('Выберите торговую пару:', replyMarkup: replyKeyboard);
//   });

//   teledart.onMessage().listen((message) async {
//     if (coinPars.contains(message.text)) {
//       userIndexChoice = message.text;
//       print('Пользователь выбрал торговую пару: ${message.text}');
//       await message.reply('Выберите верхнюю границу');

//       teledart.onMessage().take(1).listen((event1) async {
//         if (event1.text != null) {
//           print('Пользователь выбрал верхнюю границу: ${event1.text}');
//           upperLimit = event1.text;
//           await event1.reply('Выберите нижнюю границу');

//           teledart.onMessage().take(1).listen((event2) {
//             if (event2.text != null) {
//               print('Пользователь выбрал нижнюю границу: ${event2.text}');
//               lowerLimit = event2.text;
//               getIndex.getIndex(userIndexChoice);
//             }
//           });
//         }
//       });
//     }
//   });
// }

// class TradingPair {
//   String name;
//   double? upperLimit;
//   double? lowerLimit;

//   TradingPair(this.name, {this.upperLimit, this.lowerLimit});
// // }
// import 'dart:convert';
// // ignore: depend_on_referenced_packages
// import 'package:http/http.dart' as http;

// Future<Set<String>> getAllTradingPairs() async {
//   final response =
//       await http.get(Uri.parse('https://api.binance.com/api/v3/exchangeInfo'));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> data = json.decode(response.body);
//     final List<dynamic> symbols = data['symbols'];

//     // Извлекаем названия символов и добавляем их в множество
//     final Set<String> symbolNames =
//         symbols.map<String>((symbol) => symbol['symbol']).toSet();
//     print(symbolNames);
//     return symbolNames;
//   } else {
//     throw Exception('Failed to load trading pairs');
//   }
// }

// void main(List<String> args) {
//   getAllTradingPairs();
// }
