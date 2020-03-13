
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_modal_navigation/cupertino_modal_navigation.dart';

import 'modal_with_scroll.dart';

class ModalInsideModal extends StatelessWidget {
  final ScrollController scrollController;

  const ModalInsideModal({Key key, this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  CupertinoPageScaffold(
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
                      onTap: () => showCupertinoModalBottomSheet(
                        expand: true,
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context, scrollController) =>
                            ModalInsideModal(scrollController: scrollController),
                      )),

                )
          ).toList(),
        ),
      ),
    );
  }
}

