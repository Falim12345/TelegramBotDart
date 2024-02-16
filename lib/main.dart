import 'dart:convert';

import 'package:dart_application_1/repos/repository.dart';
import 'package:dart_application_1/util.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  Set<String> coinPars = await getAllTradingPairs();
  final getIndexBinance = GetIndexBinance();

  List<TradingPair> selectedPairs = [];
  String? userIndexChoice;
  String? upperLimit;
  String? lowerLimit;

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
      await message.reply('Select upper border');

      teledart.onMessage().take(1).listen((event1) async {
        if (event1.text != null) {
          print('Пользователь выбрал верхнюю границу: ${event1.text}');
          upperLimit = event1.text;
          await event1.reply('Select Bottom Border');

          teledart.onMessage().take(1).listen((event2) async {
            if (event2.text != null) {
              print('Пользователь выбрал нижнюю границу: ${event2.text}');
              lowerLimit = event2.text;
              await event2.reply(
                  'You are now tracking a trading pair $userIndexChoice with an upper $upperLimit and lower $lowerLimit boundary. To start tracking a new one, enter the command /select ');
            }
            final webSocketChannel = await getIndexBinance
                .getWebSocketChannel(userIndexChoice! /*Избавиться от !*/);
            // webSocketChannel.stream.listen((data) {
            //   print('Получены данные: $data');
            //   // Здесь вы можете выполнить дополнительные операции с полученными данными, если это необходимо
            // }, onError: (error) {
            //   print('Произошла ошибка: $error');
            // }, onDone: () {
            //   print('Соединение закрыто');
            // });

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
              if (price > double.parse(upperLimit!) ||
                  price < double.parse(lowerLimit!)) {
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
          });
        }
      });
    }
  });
}

class TradingPair {
  String name;
  double? upperLimit;
  double? lowerLimit;
  WebSocketChannel? webSocketChannel;

  TradingPair(this.name,
      {this.upperLimit, this.webSocketChannel, this.lowerLimit});

  // Фабричный метод для создания объекта TradingPair из переменных и помещения его в Map
  factory TradingPair.createFromVariables(
      String? userIndexChoice,
      String? upperLimit,
      String? lowerLimit,
      WebSocketChannel? webSocketChannel) {
    // Преобразование строковых представлений пределов в числа
    double? upperLimitValue =
        upperLimit != null ? double.tryParse(upperLimit) : null;
    double? lowerLimitValue =
        lowerLimit != null ? double.tryParse(lowerLimit) : null;

    // Создание объекта TradingPair и возвращение его
    return TradingPair(
      userIndexChoice ??
          '', // Если userIndexChoice равно null, то используется пустая строка
      upperLimit: upperLimitValue,
      lowerLimit: lowerLimitValue,
      webSocketChannel: webSocketChannel,
    );
  }
}
