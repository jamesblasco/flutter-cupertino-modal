import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_modal_navigation/cupertino_modal_navigation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoScaffold(
          body: MyHomePage(title: 'Flutter Demo Home Page')),
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
  void _incrementCounter(BuildContext context) {
    showCupertinoModalBottomSheet(
      secondAnimation: CupertinoScaffold.of(context).animation,
      expand: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context, scrollController) =>
          LanguageBottomSheet(scrollController: scrollController),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('iOS13 Modal Presentation'),
          trailing: GestureDetector(
              child: Icon(CupertinoIcons.add),
              onTap: () => _incrementCounter(context)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[],
        ));
  }
}

class LanguageBottomSheet extends StatelessWidget {
  final ScrollController scrollController;

  const LanguageBottomSheet({Key key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar:
            CupertinoNavigationBar(leading: Container(), middle: Text('Text')),
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
                        Navigator.of(context).maybePop();
                      },
                    )),
          ).toList(),
        ));
  }
}
