class Validation {
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
}
