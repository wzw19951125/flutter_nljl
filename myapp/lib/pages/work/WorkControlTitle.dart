import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/pages/work/NetworkConfigDialog.dart';

/// 工控屏的 TitleBar
/// Created in 2021-08-19 11:43:44 by YinRH
class WorkControlTitle extends StatefulWidget {
  WorkControlTitle({Key key, this.size}) : super(key: key);

  final Size size; // 组件的宽度和高度

  @override
  WorkControlTitleState createState() => WorkControlTitleState();
}

class WorkControlTitleState extends State<WorkControlTitle> {
  /// 设置，跳转到配置页面
  /// [context] BuildContext
  // void jumpSettings(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (ctx) {
  //       return NetworkConfigDialog();
  //     },
  //     barrierDismissible: false,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          // LOGO
          Container(
            padding: EdgeInsets.only(left: 20),
            width: 140,
            height: widget.size.height,
            child: Image.asset('images/bg_logo.png'),
          ),
          //
          Container(
            width: widget.size.width - 200,
            height: widget.size.height,
          ),
          // 设置
          InkWell(
            onTap: () => showDialog(
              barrierDismissible: false,
              context: context,
              builder: (ctx) {
                return KeyboardRootWidget(
                  child: NetworkConfigDialog(),
                );
              },
            ),
            child: Container(
              padding: EdgeInsets.only(right: 10, top: 10, bottom: 10),
              width: 60,
              height: widget.size.height,
              child: Image.asset('images/bg_settings.png'),
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}
