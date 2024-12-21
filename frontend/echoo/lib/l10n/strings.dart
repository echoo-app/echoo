import 'zh.dart';
import 'en.dart';
import 'ja.dart';
import 'ko.dart';
import 'fr.dart';
import 'de.dart';
import 'es.dart';
import 'ru.dart';
import 'ar.dart';
import 'fa.dart';

class AppStrings {
  /// 获取指定语言的字符串
  static String getString(String key, String languageCode) {
    return localizedValues[languageCode]?[key] ?? localizedValues['en']?[key] ?? key;
  }

  /// 获取带参数的字符串，参数使用 {0}, {1} 等占位符
  static String getStringWithArgs(String key, String languageCode, List<String> args) {
    String template = getString(key, languageCode);
    for (var i = 0; i < args.length; i++) {
      template = template.replaceAll('{$i}', args[i]);
    }
    return template;
  }

  static const Map<String, Map<String, String>> localizedValues = {
    'zh': zhStrings,
    'en': enStrings,
    'ja': jaStrings,
    'ko': koStrings,
    'fr': frStrings,
    'de': deStrings,
    'es': esStrings,
    'ru': ruStrings,
    'ar': arStrings,
    'fa': faStrings,
  };
}
