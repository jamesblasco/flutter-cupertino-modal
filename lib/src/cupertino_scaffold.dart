import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _CupertinoScaffold extends InheritedWidget {
  final AnimationController animation;

  final Widget child;

  const _CupertinoScaffold({Key key, this.animation, this.child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

class CupertinoScaffold extends StatefulWidget {
  static _CupertinoScaffold of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CupertinoScaffold>();

  final Widget body;

  const CupertinoScaffold({Key key, this.body}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CupertinoScaffoldState();
}

class _CupertinoScaffoldState extends State<CupertinoScaffold>
    with TickerProviderStateMixin {
  AnimationController animationController;

  SystemUiOverlayStyle lastStyle;

  @override
  void initState() {
    lastStyle = SystemChrome.latestStyle;

    animationController =
        AnimationController(duration: Duration(milliseconds: 350), vsync: this);
    animationController.addListener(updateStatusBar);
    super.initState();
  }

  updateStatusBar() {
    Brightness brightness;
    if (animationController.value > 0.4) {
      brightness = Brightness.dark;
    } else {
      brightness = lastStyle?.statusBarBrightness;
    }
    if (SystemChrome.latestStyle?.statusBarBrightness != brightness)
      SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(statusBarBrightness: brightness));
  }

  @override
  void dispose() {
    animationController.removeListener(updateStatusBar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double startRoundCorner = 0;
    final paddingTop = MediaQuery.of(context).padding.top;
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        paddingTop > 20)
      startRoundCorner =
          38.5; //https://kylebashour.com/posts/finding-the-real-iphone-x-corner-radius

    final  curvedAnimation =  CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOut,
    );
    return _CupertinoScaffold(
        animation: animationController,
        child: AnimatedBuilder(
            animation: curvedAnimation,
            builder: (context, child) => Stack(
                  children: <Widget>[
                    Container(
                      color: Colors.black,
                    ),
                    Transform.translate(
                      offset: Offset(0,  curvedAnimation.value * paddingTop),
                      child: Transform.scale(
                        scale: 1 - curvedAnimation.value / 10,
                      child:  ClipRRect(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                    (1 - curvedAnimation.value) *
                                            startRoundCorner +
                                        curvedAnimation.value * 12),
                                topRight: Radius.circular(
                                    (1 - curvedAnimation.value) *
                                            startRoundCorner +
                                        curvedAnimation.value * 12)),
                            child: child),
                        alignment: Alignment.topCenter,
                      ),
                    )
                  ],
                ),
            child: widget.body));
  }
}
