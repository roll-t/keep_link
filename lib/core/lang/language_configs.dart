
import 'package:keep_link/core/lang/translation_service.dart';
import 'package:keep_link/core/local_storage/app_get_storage.dart';

Future<void> languageConfigs() async {
  // Lấy ngôn ngữ mặc định, mặc định là tiếng Anh
  String language = AppGetStorage.getLanguage();
  // Thiết lập ngôn ngữ sử dụng dịch vụ localization của bạn
  LocalizationService.changeLocale(language == 'English' ? 'en' : 'vi');
}
