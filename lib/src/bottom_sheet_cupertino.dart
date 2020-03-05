// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const Duration _bottomSheetDuration = Duration(milliseconds: 400);
const double _minFlingVelocity = 500.0;
const double _closeProgressThreshold = 0.5;

typedef ScrollWidgetBuilder = Widget Function(
    BuildContext context, ScrollController controller);



class _CupertinoBottomSheetContainer extends StatelessWidget {
  final Widget child;

  const _CupertinoBottomSheetContainer({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Container(
            padding: EdgeInsets.only(top: 10),
            child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12)),
                child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 10,
                              color: Colors.black12,
                              spreadRadius: 5)
                        ]),
                    width: double.infinity,
                    child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: child)))));
  }
}

/// A material design bottom sheet.
///
/// There are two kinds of bottom sheets in material design:
///
///  * _Persistent_. A persistent bottom sheet shows information that
///    supplements the primary content of the app. A persistent bottom sheet
///    remains visible even when the user interacts with other parts of the app.
///    Persistent bottom sheets can be created and displayed with the
///    [ScaffoldState.showBottomSheet] function or by specifying the
///    [Scaffold.bottomSheet] constructor parameter.
///
///  * _Modal_. A modal bottom sheet is an alternative to a menu or a dialog and
///    prevents the user from interacting with the rest of the app. Modal bottom
///    sheets can be created and displayed with the [showModalBottomSheet]
///    function.
///
/// The [CupertinoBottomSheet] widget itself is rarely used directly. Instead, prefer to
/// create a persistent bottom sheet with [ScaffoldState.showBottomSheet] or
/// [Scaffold.bottomSheet], and a modal bottom sheet with [showModalBottomSheet].
///
/// See also:
///
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal "persistent" bottom sheets.
///  * [showModalBottomSheet], which can be used to display a modal bottom
///    sheet.
///  * <https://material.io/design/components/sheets-bottom.html>
class CupertinoBottomSheet extends StatefulWidget {
  /// Creates a bottom sheet.
  ///
  /// Typically, bottom sheets are created implicitly by
  /// [ScaffoldState.showBottomSheet], for persistent bottom sheets, or by
  /// [showModalBottomSheet], for modal bottom sheets.
  const CupertinoBottomSheet({
    Key key,
    this.animationController,
    this.enableDrag = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    @required this.onClosing,
    @required this.builder,
  })  : assert(enableDrag != null),
        assert(onClosing != null),
        assert(builder != null),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  /// The animation controller that controls the bottom sheet's entrance and
  /// exit animations.
  ///
  /// The BottomSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController animationController;

  /// Called when the bottom sheet begins to close.
  ///
  /// A bottom sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given bottom sheet.
  final VoidCallback onClosing;

  /// A builder for the contents of the sheet.
  ///
  /// The bottom sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final ScrollWidgetBuilder builder;

  /// If true, the bottom sheet can be dragged up and down and dismissed by
  /// swiping downwards.
  ///
  /// Default is true.
  final bool enableDrag;

  /// The bottom sheet's background color.
  ///
  /// Defines the bottom sheet's [Material.color].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final Color backgroundColor;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0. The value is non-negative.
  final double elevation;

  /// The shape of the bottom sheet.
  ///
  /// Defines the bottom sheet's [Material.shape].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final ShapeBorder shape;

  /// {@macro flutter.widgets.Clip}
  ///
  /// Defines the bottom sheet's [Material.clipBehavior].
  ///
  /// Use this property to enable clipping of content when the bottom sheet has
  /// a custom [shape] and the content can extend past this shape. For example,
  /// a bottom sheet with rounded corners and an edge-to-edge [Image] at the
  /// top.
  ///
  /// If this property is null then [ThemeData.bottomSheetTheme.clipBehavior] is
  /// used. If that's null then the behavior will be [Clip.none].
  final Clip clipBehavior;

  @override
  _CupertinoBottomSheetState createState() => _CupertinoBottomSheetState();

  /// Creates an [AnimationController] suitable for a
  /// [CupertinoBottomSheet.animationController].
  ///
  /// This API available as a convenience for a Material compliant bottom sheet
  /// animation. If alternative animation durations are required, a different
  /// animation controller could be provided.
  static AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: _bottomSheetDuration,
      debugLabel: 'BottomSheet',
      vsync: vsync,
    );
  }
}

class _CupertinoBottomSheetState extends State<CupertinoBottomSheet> {
  final GlobalKey _childKey = GlobalKey(debugLabel: 'BottomSheet child');

  _DraggableScrollableSheetScrollController _scrollController;
  _DraggableSheetExtent _extent;

  double get _childHeight {
    final RenderBox renderBox =
        _childKey.currentContext.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  bool get _dismissUnderway =>
      widget.animationController.status == AnimationStatus.reverse;

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(widget.enableDrag);
    _extent.dragging = true;
    if (_dismissUnderway) return;
    widget.animationController.value -=
        details.primaryDelta / (_childHeight ?? details.primaryDelta);
  }

  void _handleDragStart() {
    _extent.dragging = true;
  }

  void _handleDragEnd() {
    _extent.dragging = false;
    final velocity = _extent.velocity ?? 0;
    assert(widget.enableDrag);
    if (_dismissUnderway) return;
    if (velocity > _minFlingVelocity) {
      final double flingVelocity = -velocity / _childHeight;
      if (widget.animationController.value > 0.0) {
        widget.animationController
            .fling(velocity: flingVelocity)
            .then((value) => _extent._currentExtent.value = 1);
      }
      if (flingVelocity < 0.0) {
        widget.onClosing();
      }
    } else if (widget.animationController.value < _closeProgressThreshold) {
      if (widget.animationController.value > 0.0)
        widget.animationController
            .fling(velocity: -1.0)
            .then((value) => _extent._currentExtent.value = 1);
      widget.onClosing();
    } else {
      widget.animationController
          .forward()
          .then((value) => _extent._currentExtent.value = 1);
    }
  }

  @override
  void initState() {
    _extent = _DraggableSheetExtent(
      minExtent: 0.1,
      maxExtent: 1,
      initialExtent: 1,
      currentExtent: widget.animationController,
    );
    _scrollController =
        _DraggableScrollableSheetScrollController(extent: _extent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData bottomSheetTheme =
        Theme.of(context).bottomSheetTheme;
    final Color color =
        widget.backgroundColor ?? bottomSheetTheme.backgroundColor;
    final double elevation =
        widget.elevation ?? bottomSheetTheme.elevation ?? 0;
    final ShapeBorder shape = widget.shape ?? bottomSheetTheme.shape;
    final Clip clipBehavior =
        widget.clipBehavior ?? bottomSheetTheme.clipBehavior ?? Clip.none;

    final Widget bottomSheet = Material(
      key: _childKey,
      color: color,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      child: widget.builder(context, _scrollController),
    );
    return !widget.enableDrag
        ? bottomSheet
        : GestureDetector(
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: (_) => _handleDragEnd(),
            child: Listener(
              onPointerDown: (_) => _handleDragStart(),
              onPointerUp: (_) => _handleDragEnd(),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  _extent.availablePixels = constraints.biggest.height;
                  return _CupertinoBottomSheetContainer(child: bottomSheet);
                },
              ),
            ));
  }
}

// PERSISTENT BOTTOM SHEETS

// See scaffold.dart

// MODAL BOTTOM SHEETS
class _ModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _ModalBottomSheetLayout(this.progress, this.expand);

  final double progress;
  final bool expand;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: expand ? constraints.maxHeight : constraints.minHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_ModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    Key key,
    this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.secondAnimationController,
    this.expanded = false,
    this.enableDrag = true,
  })  : assert(expanded != null),
        assert(enableDrag != null),
        super(key: key);

  final _ModalBottomSheetRoute<T> route;
  final bool expanded;
  final Color backgroundColor;
  final double elevation;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final bool enableDrag;
  final AnimationController secondAnimationController;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}


class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  String _getRouteLabel(MaterialLocalizations localizations) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return localizations.dialogLabel;
    }
    return null;
  }

  @override
  void initState() {
    widget.route.animation.addListener(updateController);
    super.initState();
  }

  @override
  void dispose() {
    widget.route.animation.removeListener(updateController);
    super.dispose();
  }


  updateController() {
    widget.secondAnimationController?.value = widget.route.animation.value;
  }
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String routeLabel = _getRouteLabel(localizations);

    final Animation<double> curvedAnimation =  CurvedAnimation(
      parent: widget.route.animation,
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (BuildContext context, Widget child) {

         // Disable the initial animation when accessible navigation is on so
        // that the semantics are added to the tree at the correct time.
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
              delegate:
                  _ModalBottomSheetLayout(curvedAnimation.value, widget.expanded),
              child: CupertinoBottomSheet(
                animationController: widget.route._animationController,
                onClosing: () {
                  if (widget.route.isCurrent) {
                    Navigator.pop(context);
                  }
                },
                builder: widget.route.builder,
                backgroundColor: widget.backgroundColor,
                elevation: widget.elevation,
                shape: widget.shape,
                clipBehavior: widget.clipBehavior,
                enableDrag: widget.enableDrag,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModalBottomSheetRoute<T> extends PopupRoute<T> {
  _ModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.secondAnimationController,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    @required this.expanded,
    RouteSettings settings,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(settings: settings);

  final ScrollWidgetBuilder builder;
  final ThemeData theme;
  final bool expanded;
  final Color backgroundColor;
  final double elevation;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final Color modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;

  final AnimationController secondAnimationController;

  @override
  Duration get transitionDuration => _bottomSheetDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black.withOpacity(0.35);

  AnimationController _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        CupertinoBottomSheet.createAnimationController(navigator.overlay);
    return _animationController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final BottomSheetThemeData sheetTheme =
        theme?.bottomSheetTheme ?? Theme.of(context).bottomSheetTheme;
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      // removeTop: true,
      child: _ModalBottomSheet<T>(
        route: this,
        backgroundColor: backgroundColor ??
            sheetTheme?.modalBackgroundColor ??
            sheetTheme?.backgroundColor,
        elevation:
            elevation ?? sheetTheme?.modalElevation ?? sheetTheme?.elevation,
        shape: shape,
        secondAnimationController: secondAnimationController,
        clipBehavior: clipBehavior,
        expanded: expanded,
        enableDrag: enableDrag,
      ),
    );
    if (theme != null) bottomSheet = Theme(data: theme, child: bottomSheet);
    return bottomSheet;
  }

 /* @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      builder: (context, child) => Transform.scale(
        scale: secondaryAnimation.value,
        child: child,
      ),
      child: child,
      animation: secondaryAnimation,
    );
  }*/
}

/// Shows a modal material design bottom sheet.
///
/// A modal bottom sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// A closely related widget is a persistent bottom sheet, which shows
/// information that supplements the primary content of the app without
/// preventing the use from interacting with the app. Persistent bottom sheets
/// can be created and displayed with the [showBottomSheet] function or the
/// [ScaffoldState.showBottomSheet] method.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the bottom sheet. It is only used when the method is called. Its
/// corresponding widget can be safely removed from the tree before the bottom
/// sheet is closed.
///
/// The `isScrollControlled` parameter specifies whether this is a route for
/// a bottom sheet that will utilize [DraggableScrollableSheet]. If you wish
/// to have a bottom sheet that has a scrollable child such as a [ListView] or
/// a [GridView] and have the bottom sheet be draggable, you should set this
/// parameter to true.
///
/// The `useRootNavigator` parameter ensures that the root navigator is used to
/// display the [CupertinoBottomSheet] when set to `true`. This is useful in the case
/// that a modal [CupertinoBottomSheet] needs to be displayed above all other content
/// but the caller is inside another [Navigator].
///
/// The [isDismissible] parameter specifies whether the bottom sheet will be
/// dismissed when user taps on the scrim.
///
/// The [enableDrag] parameter specifies whether the bottom sheet can be
/// dragged up and down and dismissed by swiping downards.
///
/// The optional [backgroundColor], [elevation], [shape], and [clipBehavior]
/// parameters can be passed in to customize the appearance and behavior of
/// modal bottom sheets.
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal bottom sheet was closed.
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This example demonstrates how to use `showModalBottomSheet` to display a
/// bottom sheet that obscures the content behind it when a user taps a button.
/// It also demonstrates how to close the bottom sheet using the [Navigator]
/// when a user taps on a button inside the bottom sheet.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Center(
///     child: RaisedButton(
///       child: const Text('showModalBottomSheet'),
///       onPressed: () {
///         showModalBottomSheet<void>(
///           context: context,
///           builder: (BuildContext context) {
///             return Container(
///               height: 200,
///               color: Colors.amber,
///               child: Center(
///                 child: Column(
///                   mainAxisAlignment: MainAxisAlignment.center,
///                   mainAxisSize: MainAxisSize.min,
///                   children: <Widget>[
///                     const Text('Modal BottomSheet'),
///                     RaisedButton(
///                       child: const Text('Close BottomSheet'),
///                       onPressed: () => Navigator.pop(context),
///                     )
///                   ],
///                 ),
///               ),
///             );
///           },
///         );
///       },
///     ),
///   );
/// }
/// ```
/// {@end-tool}
/// See also:
///
///  * [CupertinoBottomSheet], which becomes the parent of the widget returned by the
///    function passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * [DraggableScrollableSheet], which allows you to create a bottom sheet
///    that grows and then becomes scrollable once it reaches its maximum size.
///  * <https://material.io/design/components/sheets-bottom.html#modal-bottom-sheet>
Future<T> showCupertinoModalBottomSheet<T>({
  @required BuildContext context,
  @required ScrollWidgetBuilder builder,
  Color backgroundColor,
  double elevation,
  ShapeBorder shape,
  Clip clipBehavior,
  Color barrierColor,
  bool expand = false,
  AnimationController secondAnimation,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(isDismissible != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final result = await Navigator.of(context, rootNavigator: useRootNavigator)
      .push(_ModalBottomSheetRoute<T>(
    builder: builder,
    secondAnimationController: secondAnimation,
    theme: Theme.of(context, shadowThemeOnly: true),
    expanded: expand,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor,
    enableDrag: enableDrag,
  ));
  return result;
}

/// A [ScrollController] suitable for use in a [ScrollableWidgetBuilder] created
/// by a [DraggableScrollableSheet].
///
/// If a [DraggableScrollableSheet] contains content that is exceeds the height
/// of its container, this controller will allow the sheet to both be dragged to
/// fill the container and then scroll the child content.
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollPosition], which manages the positioning logic for
///    this controller.
///  * [PrimaryScrollController], which can be used to establish a
///    [_DraggableScrollableSheetScrollController] as the primary controller for
///    descendants.
class _DraggableScrollableSheetScrollController extends ScrollController {
  _DraggableScrollableSheetScrollController({
    double initialScrollOffset = 0.0,
    String debugLabel,
    @required this.extent,
  })  : assert(extent != null),
        super(
          debugLabel: debugLabel,
          initialScrollOffset: initialScrollOffset,
        );

  final _DraggableSheetExtent extent;

  @override
  _DraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return _DraggableScrollableSheetScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      extent: extent,
    );
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('extent: $extent');
  }
}

class _DraggableSheetExtent {
  _DraggableSheetExtent({
    @required this.minExtent,
    @required this.maxExtent,
    @required this.initialExtent,
    AnimationController currentExtent,
  })  : assert(minExtent != null),
        assert(maxExtent != null),
        assert(initialExtent != null),
        assert(minExtent >= 0),
        assert(maxExtent <= 1),
        assert(minExtent <= initialExtent),
        assert(initialExtent <= maxExtent),
        _currentExtent = currentExtent,
        availablePixels = double.infinity;

  final double minExtent;
  final double maxExtent;
  final double initialExtent;
  final AnimationController _currentExtent;
  double availablePixels;
  double velocity;
  bool dragging = false;

  bool get isAtMin => minExtent >= _currentExtent.value;

  bool get isAtMax => maxExtent <= _currentExtent.value;

  set currentExtent(double value) {
    assert(value != null);
    _currentExtent.value = value.clamp(minExtent, maxExtent) as double;
  }

  double get currentExtent => _currentExtent.value;

  double get additionalMinExtent => isAtMin ? 0.0 : 1.0;

  double get additionalMaxExtent => isAtMax ? 0.0 : 1.0;

  /// The scroll position gets inputs in terms of pixels, but the extent is
  /// expected to be expressed as a number between 0..1.
  void addPixelDelta(double delta, double velocity, BuildContext context) {
    if (availablePixels == 0) {
      return;
    }
    if (dragging) {
      velocity = velocity;
      currentExtent += delta / availablePixels * maxExtent;
      DraggableScrollableNotification(
        minExtent: minExtent,
        maxExtent: maxExtent,
        extent: currentExtent,
        initialExtent: initialExtent,
        context: context,
      ).dispatch(context);
    }
  }
}

/// A scroll position that manages scroll activities for
/// [_DraggableScrollableSheetScrollController].
///
/// This class is a concrete subclass of [ScrollPosition] logic that handles a
/// single [ScrollContext], such as a [Scrollable]. An instance of this class
/// manages [ScrollActivity] instances, which changes the
/// [_DraggableSheetExtent.currentExtent] or visible content offset in the
/// [Scrollable]'s [Viewport]
///
/// See also:
///
///  * [_DraggableScrollableSheetScrollController], which uses this as its [ScrollPosition].
class _DraggableScrollableSheetScrollPosition
    extends ScrollPositionWithSingleContext {
  _DraggableScrollableSheetScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.extent,
  })  : assert(extent != null),
        super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  VoidCallback _dragCancelCallback;
  final _DraggableSheetExtent extent;

  bool get listShouldScroll => pixels > 0.0;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // We need to provide some extra extent if we haven't yet reached the max or
    // min extents. Otherwise, a list with fewer children than the extent of
    // the available space will get stuck.
    return super.applyContentDimensions(
      minScrollExtent - extent.additionalMinExtent,
      maxScrollExtent + extent.additionalMaxExtent,
    );
  }

  @override
  void applyUserOffset(double delta) {
    if (!listShouldScroll &&
        (!(extent.isAtMin || extent.isAtMax) ||
            (extent.isAtMin && delta < 0) ||
            (extent.isAtMax && delta > 0))) {
      extent.addPixelDelta(-delta, 0, context.notificationContext);
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void goBallistic(double velocity) {
    if (velocity == 0.0 ||
        (velocity < 0.0 && listShouldScroll) ||
        (velocity > 0.0 && extent.isAtMax)) {
      super.goBallistic(velocity);
      return;
    }
    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    // The iOS bouncing simulation just isn't right here - once we delegate
    // the ballistic back to the ScrollView, it will use the right simulation.
    final Simulation simulation = ClampingScrollSimulation(
      position: extent.currentExtent,
      velocity: velocity,
      tolerance: physics.tolerance,
    );
    // TODO: Cancel/Dispose if modal is popped
    final AnimationController ballisticController =
        AnimationController.unbounded(
      debugLabel: objectRuntimeType(this, '_DraggableScrollableSheetPosition'),
      vsync: context.vsync,
    );
    double lastDelta = 0;
    void _tick() {
      final double delta = ballisticController.value - lastDelta;
      lastDelta = ballisticController.value;
      extent.addPixelDelta(delta, velocity, context.notificationContext);
      if ((velocity > 0 && extent.isAtMax) ||
          (velocity < 0 && extent.isAtMin)) {
        // Make sure we pass along enough velocity to keep scrolling - otherwise
        // we just "bounce" off the top making it look like the list doesn't
        // have more to scroll.
        velocity = ballisticController.velocity +
            (physics.tolerance.velocity * ballisticController.velocity.sign);
        super.goBallistic(velocity);
        ballisticController.stop();
      } else if (ballisticController.isCompleted) {
        super.goBallistic(0);
      }
    }

    ballisticController
      ..addListener(_tick)
      ..animateWith(simulation).whenCompleteOrCancel(
        ballisticController.dispose,
      );
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}
