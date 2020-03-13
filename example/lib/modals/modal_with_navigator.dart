
import 'package:flutter/cupertino.dart';
import 'package:cupertino_modal_navigation/cupertino_modal_navigation.dart';
import 'package:flutter/material.dart';

class ModalWithNavigator extends StatelessWidget {
  final ScrollController scrollController;

  const ModalWithNavigator({Key key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => CupertinoScaffold(
                body: Builder(
                  builder: (context) => CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                        leading: Container(), middle: Text('Modal Page')),
                    child: SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        controller: scrollController,
                        children: ListTile.divideTiles(
                          context: context,
                          tiles: List.generate(
                              100,
                                  (index) => ListTile(
                                title: Text('Item'),
                                onTap: () {
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CupertinoPageScaffold(
                                                  navigationBar:
                                                  CupertinoNavigationBar(
                                                    middle: Text(
                                                        'New Page'),
                                                  ),
                                                  child: Stack(
                                                    fit:
                                                    StackFit.expand,
                                                    children: <
                                                        Widget>[],
                                                  ))));
                                },
                              )),
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ))
    );
  }
}

