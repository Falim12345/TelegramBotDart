import 'dart:async';
import 'dart:convert';

import 'package:dart_application_1/model/trading_pair.dart';
import 'package:dart_application_1/repos/repository.dart';
import 'package:dart_application_1/util.dart';
import 'package:dart_application_1/valid.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

void main() async {
  Set<String> coinPairs = await getAllTradingPairs();

  final getIndexBinance = GetIndexBinance();

  List<TradingPair> selectedPairs = [];

  String? userIndexChoice;
  String? upperLimit;
  String? lowerLimit;

  bool isWaitingForUpperLimit = false;
  bool isWaitingForLowerLimit = false;

  final username = (await Telegram(BotUtil.botToken).getMe()).username;
  var teledart = TeleDart(BotUtil.botToken, Event(username!));
  List<Map<String, dynamic>> messages = [];

  teledart.start();
  teledart.onCommand('start').listen((event) async {
    await event.reply(
        'Good day, to select the currency pair you want to track, select the command /select \u{1F388}\u{270C} ');
  });

  teledart.onCommand('select').listen((event) async {
    var keyboard = coinPairs.map((e) => [KeyboardButton(text: e)]).toList();

    var replyKeyboard = ReplyKeyboardMarkup(
        keyboard: keyboard,
        resizeKeyboard: true,
        oneTimeKeyboard: true,
        selective: true);
    await event.reply('Select a trading pair', replyMarkup: replyKeyboard);
  });

  teledart.onMessage().listen((message) async {
    messages.add({
      'text': message.text,
      'timestamp': DateTime.now(),
    });

    // var userId = message.from?.id;
    // print(userId);
    var userId = message.from?.username;
    print(userId);

    if (coinPairs.contains(message.text)) {
      userIndexChoice = message.text;
      print('User selected trading pair: ${message.text}');
      await message.reply('Select upper border');
      isWaitingForUpperLimit = true;
    } else if (isWaitingForUpperLimit) {
      if (Validation().isValidLimit(message.text ?? 'nonValid')) {
        print('User selected upper limit: ${message.text}');
        upperLimit = message.text;
        await message.reply('Select Bottom Border');
        isWaitingForUpperLimit = false;
        isWaitingForLowerLimit = true;
      } else {
        await message.reply('Upper limit is not valid. Please try again.');
      }
    } else if (isWaitingForLowerLimit) {
      lowerLimit = message.text;
      if (Validation().isValidLimit(message.text ?? 'nonValid') &&
          double.parse(message.text!) < double.parse(upperLimit ?? '0') &&
          double.parse(message.text!) != double.parse(upperLimit ?? '0')) {
        lowerLimit = message.text;
        print('User selected lower limit: ${message.text}');
        await message.reply(
            'You are now tracking a trading pair $userIndexChoice with an upper $upperLimit and lower $lowerLimit boundary. To start tracking a new one, enter the command /select');
        isWaitingForLowerLimit = false;

        final webSocketChannel =
            await getIndexBinance.getWebSocketChannel(userIndexChoice ?? '');

        var tradingPair = TradingPair.createFromVariables(
          userIndexChoice,
          upperLimit,
          lowerLimit,
          webSocketChannel,
        );
        selectedPairs.add(tradingPair);
        print('Added object to List: $tradingPair');
        print(selectedPairs);

        webSocketChannel.stream.listen((data) async {
          print(data);
          // Parse data
          var jsonData = json.decode(data);
          var symbol = jsonData['s'];
          var price = double.parse(jsonData['p']);

          if (price > tradingPair.upperLimit!) {
            print(tradingPair.upperLimit);
            await message.reply(
                '#up\u{1F4C8}\u{2197} $symbol > ${tradingPair.upperLimit}.');

            webSocketChannel.sink.close();
          } else if (price < tradingPair.lowerLimit!) {
            print(tradingPair.lowerLimit);
            await message.reply(
                '#down\u{1F4C9}\u{2198} $symbol < ${tradingPair.lowerLimit}.');

            webSocketChannel.sink.close();
          }
        }, onError: (error) {
          print('An error occurred: $error');
        }, onDone: () {
          print('Connection closed');
        });
      } else {
        await message.reply('Lower limit is not valid. Please try again.');
      }
    } else {
      await message.reply('Invalid trading pair. Please try again.');
    }
  });

  teledart.onCommand('history').listen((event) async {
    if (selectedPairs.isNotEmpty) {
      var pairsMessage = selectedPairs
          .map((element) =>
              'Currency pair ${element.name}, Upper limit: ${element.upperLimit}, Lower limit: ${element.lowerLimit}, Tracking Status: ${element.webSocketChannel?.closeReason == null ? "Connection Open" : "Connection Closed"}')
          .join('\n');

      await event.reply(pairsMessage);
    } else {
      await event
          .reply('There are no trading pairs selected. Please try again.');
    }
  });

  teledart.onCommand('spotlight').listen((event) async {
    var activePairs = selectedPairs
        .where((pair) => pair.webSocketChannel?.closeReason == null);

    if (activePairs.isNotEmpty) {
      // Собираем все строки для активных подключений в одну
      var activePairsMessage = activePairs
          .map((pair) =>
              'Currency pair ${pair.name}, Upper limit: ${pair.upperLimit}, Lower limit: ${pair.lowerLimit}, Connection Status: Open')
          .join('\n');

      await event.reply(activePairsMessage);
    } else {
      await event.reply('There are no active trading pairs. Please try again.');
    }
  });
}
