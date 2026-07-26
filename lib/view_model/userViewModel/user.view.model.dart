import 'package:flutter/material.dart';
import 'package:mvvm/models/userModel/user.model.dart';

import '../../core/result/result.dart';
import '../../core/state/view.state.dart';
import '../../repository/userRepo/base.user.repo.dart';

class UserVM extends ChangeNotifier {
  final BaseUserRepo _userRepo;

  UserVM(this._userRepo);

  ViewState<UserModel> state = const ViewStateLoading();

  Future<void> fetchUserData() async {
    state = const ViewStateLoading();
    notifyListeners();

    final result = await _userRepo.getUserData();
    state = switch (result) {
      Ok(value: final value) => ViewStateSuccess(value),
      Err(failure: final failure) => ViewStateError(failure.message),
    };
    notifyListeners();
  }
}
