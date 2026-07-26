import 'package:get_it/get_it.dart';

import '../../data/remote/network/base.api.service.dart';
import '../../data/remote/network/network.api.service.dart';
import '../../repository/userRepo/base.user.repo.dart';
import '../../repository/userRepo/user.repo.dart';
import '../../view_model/userViewModel/user.view.model.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<BaseApiService>(() => NetworkApiService());
  sl.registerLazySingleton<BaseUserRepo>(() => UserRepo(sl()));
  sl.registerFactory<UserVM>(() => UserVM(sl()));
}
