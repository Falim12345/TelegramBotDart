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
  List<int> messages = [];

  String? userIndexChoice;
  String? upperLimit;
  String? lowerLimit;

  bool isWaitingForUpperLimit = false;
  bool isWaitingForLowerLimit = false;

  final username = (await Telegram(BotUtil.botToken).getMe()).username;
  var teledart = TeleDart(BotUtil.botToken, Event(username!));

  teledart.start();
  teledart.onMessage().listen(
    (message) {
      messages.add(message.messageId);
    },
  );

  teledart.onCommand('start').listen(
    (message) async {
      var ferstReply = await message.reply(
          'Good day, to select the currency pair you want to track, select the command /select \u{1F388}\u{270C} ');
      ferstReply;
      messages.add(ferstReply.messageId);

      messages.add(message.messageId);
    },
  );

  teledart.onCommand('select').listen(
    (message) async {
      var keyboard = coinPairs.map((e) => [KeyboardButton(text: e)]).toList();

      var replyKeyboard = ReplyKeyboardMarkup(
          keyboard: keyboard,
          resizeKeyboard: true,
          oneTimeKeyboard: true,
          selective: true);
      var secondReply = await message.reply('Select a trading pair',
          replyMarkup: replyKeyboard);
      secondReply;
      messages.add(secondReply.messageId);
    },
  );

  teledart.onMessage().listen(
    (message) async {
      if (coinPairs.contains(message.text)) {
        userIndexChoice = message.text;
        print('User selected trading pair: ${message.text}');
        var thirdReply = await message.reply('Select upper border');
        thirdReply;
        messages.add(thirdReply.messageId);
        isWaitingForUpperLimit = true;
      } else if (isWaitingForUpperLimit) {
        if (Validation().isValidLimit(message.text ?? 'nonValid')) {
          print('User selected upper limit: ${message.text}');
          upperLimit = message.text;
          var fourthReply = await message.reply('Select Bottom Border');
          fourthReply;
          messages.add(fourthReply.messageId);
          isWaitingForUpperLimit = false;
          isWaitingForLowerLimit = true;
        } else {
          var fifthReply = await message
              .reply('Upper limit is not valid. Please try again.');
          fifthReply;
          messages.add(fifthReply.messageId);
        }
      } else if (isWaitingForLowerLimit) {
        lowerLimit = message.text;
        if (Validation().isValidLimit(message.text ?? 'nonValid') &&
            double.parse(message.text!) < double.parse(upperLimit ?? '0') &&
            double.parse(message.text!) != double.parse(upperLimit ?? '0')) {
          lowerLimit = message.text;
          print('User selected lower limit: ${message.text}');
          var sixthReply = await message.reply(
              'You are now tracking a trading pair $userIndexChoice with an upper $upperLimit and lower $lowerLimit boundary. To start tracking a new one, enter the command /select');
          isWaitingForLowerLimit = false;
          sixthReply;
          messages.add(sixthReply.messageId);
          final webSocketChannel = await getIndexBinance.getWebSocketChannel(
            userIndexChoice?.toLowerCase() ?? '',
          );
          var messagesToDelete = List.from(messages);
          for (var messageId in messagesToDelete) {
            Timer(
              Duration(minutes: 1),
              () async {
                await teledart.deleteMessage(message.chat.id, messageId);
                messages.remove(messageId);
              },
            );
          }

          var tradingPair = TradingPair.createFromVariables(
            userIndexChoice,
            upperLimit,
            lowerLimit,
            webSocketChannel,
          );
          selectedPairs.add(tradingPair);

          webSocketChannel.stream.listen(
            (data) async {
              print(data);
              var jsonData = json.decode(data);
              var symbol = jsonData['s'];
              var price = double.parse(jsonData['w']);

              if (price > tradingPair.upperLimit!) {
                var seventhReply = await message.reply(
                    '#up\u{1F4C8}\u{2197} $symbol > ${tradingPair.upperLimit}.');
                seventhReply;
                print('пересекла верхний предел Средняя цена $price');

                webSocketChannel.sink.close();
              } else if (price < tradingPair.lowerLimit!) {
                print(tradingPair.lowerLimit.runtimeType);
                print(price.runtimeType);
                var eightthReply = await message.reply(
                    '#down\u{1F4C9}\u{2198} $symbol < ${tradingPair.lowerLimit}.');
                eightthReply;
                print('пересекла нижний предел Средняя цена $price');

                webSocketChannel.sink.close();
              }
            },
            onError: (error) {
              print('An error occurred: $error');
            },
            onDone: () {
              print('Connection closed ${tradingPair.name}');
            },
          );
        } else {
          var ninethReply = await message
              .reply('Lower limit is not valid. Please try again.');
          ninethReply;
          messages.add(ninethReply.messageId);
        }
      } else {
        var thenthReply =
            await message.reply('Invalid trading pair. Please try again.');
        thenthReply;
        messages.add(thenthReply.messageId);
      }
    },
  );

  teledart.onCommand('history').listen(
    (event) async {
      if (selectedPairs.isNotEmpty) {
        var pairsMessage = selectedPairs
            .map((element) =>
                'Currency pair ${element.name}, Upper limit: ${element.upperLimit}, Lower limit: ${element.lowerLimit}, Tracking Status: ${element.webSocketChannel?.closeReason == null ? "Connection Open" : "Connection Closed"}')
            .join('\n');

        var eleventhReply = await event.reply(pairsMessage);
        eleventhReply;
        messages.add(eleventhReply.messageId);
      } else {
        var twelfthReply = await event
            .reply('There are no trading pairs selected. Please try again.');
        twelfthReply;
        messages.add(twelfthReply.messageId);
      }
    },
  );

  teledart.onCommand('spotlight').listen(
    (event) async {
      var activePairs = selectedPairs
          .where((pair) => pair.webSocketChannel?.closeReason == null);

      if (activePairs.isNotEmpty) {
        var activePairsMessage = activePairs
            .map((pair) =>
                'Currency pair ${pair.name}, Upper limit: ${pair.upperLimit}, Lower limit: ${pair.lowerLimit}, Connection Status: Open')
            .join('\n');

        var thirteenthReply = await event.reply(activePairsMessage);
        thirteenthReply;
        messages.add(thirteenthReply.messageId);
      } else {
        var fourteenthReply = await event
            .reply('There are no active trading pairs. Please try again.');
        fourteenthReply;
        messages.add(fourteenthReply.messageId);
      }
    },
  );
}
