import 'dart:convert';

import 'package:dart_application_1/model/trading_pair.dart';
import 'package:dart_application_1/repos/repository.dart';
import 'package:dart_application_1/util.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

void main() async {
  Set<String> coinPars = await getAllTradingPairs();
  final getIndexBinance = GetIndexBinance();

  List<TradingPair> selectedPairs = [];
  String? userIndexChoice;
  String? upperLimit;
  String? lowerLimit;

  bool isValidPair = false;
  bool isUpperLimitValid = false;
  bool islowerLimitValid = false;

  final username = (await Telegram(BotUtil.botToken).getMe()).username;
  var teledart = TeleDart(BotUtil.botToken, Event(username!));

  teledart.start();
  teledart.onCommand('start').listen((event) async {
    await event.reply(
        'Good day, to select the currency pair you want to track, select the command /select \u{1F388}\u{270C} ');
  });

  teledart.onCommand('select').listen((event) async {
    var keyboard = coinPars.map((e) => [KeyboardButton(text: e)]).toList();

    var replyKeyboard = ReplyKeyboardMarkup(
        keyboard: keyboard,
        resizeKeyboard: true,
        oneTimeKeyboard: true,
        selective: true);
    await event.reply('Select a trading pair', replyMarkup: replyKeyboard);
  });

  teledart.onMessage().listen((message) async {
    if (coinPars.contains(message.text)) {
      userIndexChoice = message.text;
      print('Пользователь выбрал торговую пару: ${message.text}');
      isValidPair = true;
      await message.reply('Select upper border');

      teledart.onMessage().listen((event1) async {
        if (isValidLimit(event1.text ?? 'nonValid')) {
          print('Пользователь выбрал верхнюю границу: ${event1.text}');
          isUpperLimitValid = true;
          upperLimit = event1.text;
          await event1.reply('Select Bottom Border');

          teledart.onMessage().listen((event2) async {
            if (isValidLimit(event2.text ?? 'nonValid')) {
              print('Пользователь выбрал нижнюю границу: ${event2.text}');
              lowerLimit = event2.text;
              islowerLimitValid = true;
              await event2.reply(
                  'You are now tracking a trading pair $userIndexChoice with an upper $upperLimit and lower $lowerLimit boundary. To start tracking a new one, enter the command /select ');
              final webSocketChannel = await getIndexBinance
                  .getWebSocketChannel(userIndexChoice ?? '');

              var tradingPair = TradingPair.createFromVariables(
                userIndexChoice,
                upperLimit,
                lowerLimit,
                webSocketChannel,
              );

              selectedPairs.add(tradingPair);
              print('Добавлен объект в List: $tradingPair');
              print(selectedPairs);

              webSocketChannel.stream.listen((data) async {
                print(data);
                // Парсинг данных
                var jsonData = json.decode(data);
                var symbol = jsonData['s']; // торговая пара
                var price = double.parse(jsonData['p']); // текущая цена

                // Сравнение с верхней и нижней границами
                if (price > double.parse(upperLimit ?? '') ||
                    price < double.parse(lowerLimit ?? '')) {
                  // Отправка уведомления
                  await message.reply(
                      'The price for the $symbol pair has crossed the specified boundaries.');
                  // Закрытие соединения для данной пары
                  webSocketChannel.sink.close();
                }
              }, onError: (error) {
                print('Произошла ошибка: $error');
              }, onDone: () {
                print('Соединение закрыто');
              });
            } else {
              if (!islowerLimitValid) {
                await message
                    .reply('Нижний лимит задан не верно попробуйте еще раз.');
              }
            }
          });
        } else {
          if (!isUpperLimitValid) {
            await message
                .reply('Верхний лимит задан не верно попробуйте еще раз.');
          }
        }
      });
    } else {
      if (!isValidPair) {
        await message.reply('Торговая пара не найдена. Попробуйте еще раз.');
      }
    }
  });
}

bool isValidLimit(String input) {
  try {
    double value = double.parse(input.replaceAll(',', '.'));
    if (value.isNaN || value.isInfinite) {
      return false;
    }
    if (!RegExp(r'^[0-9]+(?:\.[0-9]+)?$').hasMatch(input)) {
      return false;
    }
    // Дополнительные условия, если необходимо
    return true;
  } catch (e) {
    return false; // Ошибка при преобразовании или иное исключение
  }
}
