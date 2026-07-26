import '../../core/result/result.dart';
import '../../models/userModel/user.model.dart';

abstract class BaseUserRepo {
  Future<Result<UserModel>> getUserData();
}
