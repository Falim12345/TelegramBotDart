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
      if (Validation().isValidLimit(message.text ?? 'nonValid')) {
        lowerLimit = message.text;
        print('User selected lower limit: ${message.text}');
        await message.reply(
            'You are now tracking a trading pair $userIndexChoice with an upper $upperLimit and lower $lowerLimit boundary. To start tracking a new one, enter the command /select');
        isWaitingForLowerLimit = false;

        // Process the selected trading pair with limits
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
          var symbol = jsonData['s']; // trading pair
          var price = double.parse(jsonData['p']); // current price

          // Compare with upper and lower limits
          if (price > double.parse(upperLimit ?? '') ||
              price < double.parse(lowerLimit ?? '')) {
            // Send notification
            await message.reply(
                'The price for the $symbol pair has crossed the specified boundaries.');
            // Close connection for this pair
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
}
