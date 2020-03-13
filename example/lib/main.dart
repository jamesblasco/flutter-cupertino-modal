import 'package:example/modals/modal_fit.dart';
import 'package:example/modals/modal_simple.dart';
import 'package:example/modals/modal_will_scope.dart';
import 'package:example/modals/modal_with_navigator.dart';
import 'package:example/modals/modal_with_scroll.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_modal_navigation/cupertino_modal_navigation.dart';

import 'modals/modal_complex_all.dart';
import 'modals/modal_inside_modal.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:
          CupertinoScaffold(body: MyHomePage(title: 'Flutter Demo Home Page')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  @override
  Widget build(BuildContext context) {
    return Material(child: CupertinoPageScaffold(
      backgroundColor: Colors.white,
        navigationBar: CupertinoNavigationBar(
          middle: Text('iOS13 Modal Presentation'),
        ),
        child: SizedBox.expand( child: SingleChildScrollView(child: SafeArea(
          bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            ListTile(title: Text('Modal Simple') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  SimpleModal(scrollController: scrollController),
            )),
            ListTile(title: Text('Modal with Scroll') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ModalWithScroll(scrollController: scrollController),
            )),
            ListTile(title: Text('Modal with Navigator') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ModalWithNavigator(scrollController: scrollController),
            )),  ListTile(title: Text('Modal with WillScope') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ModalWillScope(scrollController: scrollController),
            )),
            ListTile(title: Text('Modal fit') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: false,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ModalFit(scrollController: scrollController),
            )),
            ListTile(title: Text('Modal inside modal') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ModalInsideModal(scrollController: scrollController),
            )),
            ListTile(title: Text('Navigator + Scroll + WillScope') , onTap: () =>  showCupertinoModalBottomSheet(
              secondAnimation: CupertinoScaffold.of(context).animation,
              expand: true,
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context, scrollController) =>
                  ComplexModal(scrollController: scrollController),
            ))
          ],
        ))))));
  }
}
