import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_modal_navigation/cupertino_modal_navigation.dart';

class SimpleModal extends StatelessWidget {
  final ScrollController scrollController;

  const SimpleModal({Key key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          leading: Container(), middle: Text('Modal Page')),
      child: Center(),
    );
  }
}
