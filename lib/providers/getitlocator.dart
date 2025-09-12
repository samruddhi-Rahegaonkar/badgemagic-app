import 'package:get_it/get_it.dart';

import 'package:badgemagic/providers/font_provider.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:badgemagic/services/localization_service.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<InlineImageProvider>(() => InlineImageProvider());
  getIt.registerLazySingleton<BadgeAliasProvider>(() => BadgeAliasProvider());
  getIt.registerLazySingleton<FontProvider>(() => FontProvider());
  getIt.registerLazySingleton<BadgeScanProvider>(() => BadgeScanProvider());
  getIt.registerLazySingleton<LocalizationService>(() => LocalizationService());
}
