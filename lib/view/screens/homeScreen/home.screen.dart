import 'package:flutter/material.dart';
import 'package:mvvm/models/userModel/user.model.dart';
import '../../../res/app.context.extension.dart';
import '../../shared/loading.widget.dart';
import '../../shared/my.error.widget.dart';
import '../../shared/my.text.view.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service.locator.dart';
import '../../../core/state/view.state.dart';
import '../../../view_model/userViewModel/user.view.model.dart';
import '../userScreen/user.screen.dart';

class HomeScreen extends StatefulWidget {
  static const String id = "home_screen";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserVM viewModel = sl<UserVM>();

  @override
  void initState() {
    viewModel.fetchUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: MyTextView(label: 'Test')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ChangeNotifierProvider<UserVM>(
        create: (BuildContext context) => viewModel,
        child: Consumer<UserVM>(builder: (context, viewModel, _) {
          return switch (viewModel.state) {
            ViewStateLoading() => LoadingWidget(),
            ViewStateError(:final message) => MyErrorWidget(message),
            ViewStateSuccess(:final data) => _getUsersListView(data.users),
          };
        }),
      ),
    );
  }

  Widget _getUsersListView(List<User>? users) {
    return ListView.builder(
        itemCount: users?.length,
        itemBuilder: (context, position) {
          return _getUserListItem(users![position]);
        });
  }

  Widget _getUserListItem(User item) {
    return Card(
      shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(10))),
      child: ListTile(
        title: MyTextView(label: item.name),
        subtitle: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: MyTextView(label: item.note),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: MyTextView(label: item.phone),
          ),
        ]),
        onTap: () {
          _goToDetailScreen(context, item);
        },
      ),
      elevation: context.resources.dimension.lightElevation,
    );
  }

  void _goToDetailScreen(BuildContext context, User item) {
    Navigator.pushNamed(context, UserDetailsScreen.id, arguments: item);
  }
}
