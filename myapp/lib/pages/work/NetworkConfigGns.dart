import 'dart:async';

import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/db/DbUtils.dart';
import 'package:myapp/utils/socket/GnsTcpUtils.dart';
import 'package:myapp/utils/style/StyleUtils.dart';

/// 网络配置屏之TCP
/// Created in 2021-08-19 11:43:44 by YinRH
class NetworkConfigGns extends StatefulWidget {
  NetworkConfigGns({Key key, this.size}) : super(key: key);

  final Size size;

  @override
  NetworkConfigGnsState createState() => NetworkConfigGnsState();
}

class NetworkConfigGnsState extends State<NetworkConfigGns> {
  StyleUtils _styleUtils = StyleUtils();
  TextEditingController _tecIp = TextEditingController(text: '');
  TextEditingController _tecPort = TextEditingController(text: '');
  String _modifyTitle = '修改'; // 修改或保存
  bool _hasConnect = false; // 是否已连接 Gns，true-已连接
  bool _hasModify = false; // 是否已修改，true-是
  bool _hasDispose = false; // 是否已dispose页面/弹窗

  @override
  void initState() {
    super.initState();
    DbUtils.instance.add(DbBean(
        type: 0,
        cb: (bean) {
          _tecIp.text = bean.ip;
          _tecPort.text = bean.port;
        }));
    _hasConnect = GnsTcpUtils.instance.mHasConnect;
    GnsTcpUtils.instance.upgrade((bool hasConnect) {
      if (this._hasDispose) return;
      setState(() {
        this._hasConnect = hasConnect;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    this._hasDispose = true;
  }

  /// 连接或断开
  void _changed() {
    CoolKeyboard.hideKeyboard();
    this._delayed(() {
      GnsTcpUtils.instance.changed(_hasConnect);
    });
  }

  /// 修改或保存
  void _modify() {
    CoolKeyboard.hideKeyboard();
    this._delayed(() {
      this._modifyTitle = !this._hasModify ? '保存' : '修改';
      this._hasModify = !this._hasModify;
      if (this._hasModify) return;
      GnsBean gnsBean = GnsBean();
      gnsBean.ip = _tecIp.text;
      gnsBean.port = _tecPort.text;
      DbUtils.instance.add(DbBean(type: 1, ob: gnsBean));
      GnsTcpUtils.instance.mHasConnect = false;
      this._hasConnect = false;
      GnsTcpUtils.instance.connect(_tecIp.text, _tecPort.text);
    });
  }

  /// 延迟处理
  /// [cb] 回调
  void _delayed(Function cb) {
    Timer(Duration(milliseconds: 600), () {
      setState(() {
        cb();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.size.width;
    double height = widget.size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.only(top: 15),
          alignment: Alignment.topCenter,
          width: width,
          height: 50,
          child: Text(
            '传感网络',
            textAlign: TextAlign.center,
            style: _styleUtils.textStyle(16, 0),
          ),
        ),
        Container(
          width: width,
          height: height - 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      width: 90,
                      height: 50,
                      child: Text(
                        '监听地址',
                        textAlign: TextAlign.left,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      margin: EdgeInsets.only(
                        right: width - 290,
                        top: 6,
                        bottom: 6,
                      ),
                      alignment: Alignment.centerLeft,
                      width: 200,
                      height: 38,
                      child: TextField(
                        keyboardType: NumberKeyboard.inputType,
                        textAlign: TextAlign.left,
                        controller: _tecIp,
                        maxLines: 1,
                        decoration: null,
                        enabled: this._hasModify,
                        style: _styleUtils.textStyle(14, 1),
                      ),
                      decoration: _styleUtils.border(0, 4),
                    ),
                  ],
                ),
              ),
              Container(
                width: width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      width: 90,
                      height: 50,
                      child: Text(
                        '监听端口',
                        textAlign: TextAlign.left,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      margin: EdgeInsets.only(
                        right: width - 290,
                        top: 6,
                        bottom: 6,
                      ),
                      alignment: Alignment.centerLeft,
                      width: 200,
                      height: 38,
                      child: TextField(
                        keyboardType: NumberKeyboard.inputType,
                        textAlign: TextAlign.left,
                        controller: _tecPort,
                        maxLines: 1,
                        decoration: null,
                        enabled: this._hasModify,
                        style: _styleUtils.textStyle(14, 1),
                      ),
                      decoration: _styleUtils.border(0, 4),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 20),
                margin: EdgeInsets.only(top: 10),
                width: width,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: 110,
                      height: 40,
                      child: _styleUtils.connect(1, _hasConnect, () {
                        this._changed(); // 连接或断开
                      }),
                    ),
                    Container(
                      width: 20,
                      height: 40,
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: 110,
                      height: 40,
                      child: _styleUtils.normal(_modifyTitle, 14, () {
                        this._modify(); // 修改或保存
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
