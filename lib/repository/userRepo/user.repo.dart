import 'package:mvvm/models/userModel/user.model.dart';

import '../../core/error/app.failure.dart';
import '../../core/result/result.dart';
import '../../data/remote/network/api.end.points.dart';
import '../../data/remote/network/base.api.service.dart';
import 'base.user.repo.dart';

class UserRepo implements BaseUserRepo {
  final BaseApiService _apiService;

  UserRepo(this._apiService);

  @override
  Future<Result<UserModel>> getUserData() async {
    try {
      final response = await _apiService.getResponse(ApiEndPoints().SIGN_IN);
      return Ok(UserModel.fromJson(response));
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
