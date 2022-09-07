import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/work/NetworkConfigGns.dart';
import 'package:myapp/pages/work/NetworkConfigPlc.dart';
import 'package:myapp/utils/style/StyleUtils.dart';

/// 网络配置的弹窗
/// Created in 2021-08-24 11:43:44 by YinRH
// ignore: must_be_immutable
class NetworkConfigDialog extends Dialog {
  StyleUtils _styleUtils = StyleUtils();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; // 屏幕的尺寸
    double dialogW = size.width * 0.7; // Dialog宽度
    double dialogH = size.height * 0.7; // Dialog高度
    double configH = dialogH - 65; // 配置区高度
    double configW = dialogW / 2 - 0.2; // 配置区宽度
    return KeyboardMediaQuery(
      child: Builder(builder: (builder) {
        return Material(
          child: Center(
            child: Container(
              width: dialogW,
              height: dialogH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: dialogW,
                    height: configH,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: configW,
                          height: configH,
                          child: NetworkConfigPlc(size: Size(configW, configH)),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 50, bottom: 20),
                          width: 0.4,
                          height: configH - 70,
                          decoration: BoxDecoration(color: Colors.white),
                        ),
                        Container(
                          width: configW,
                          height: configH,
                          child: NetworkConfigGns(size: Size(configW, configH)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    alignment: Alignment.center,
                    width: 145,
                    height: 45,
                    child: _styleUtils.normal('关闭', 16, () {
                      Navigator.pop(context);
                    }),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 30, 43, 82),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          type: MaterialType.transparency,
        );
      }),
    );
  }
}
