import 'package:get_it/get_it.dart';
import 'package:badgemagic/providers/imageprovider.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<InlineImageProvider>(() => InlineImageProvider());

  getIt.registerLazySingleton<BadgeAliasProvider>(() => BadgeAliasProvider());
}
