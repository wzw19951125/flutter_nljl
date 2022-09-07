import 'dart:async';
import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/socket/PlcTcpUtils.dart';
import 'package:myapp/utils/style/StyleUtils.dart';

/// 网络配置屏之TCP
/// Created in 2021-08-19 11:43:44 by YinRH
class NetworkConfigPlc extends StatefulWidget {
  NetworkConfigPlc({Key key, this.size}) : super(key: key);

  final Size size;

  @override
  NetworkConfigPlcState createState() => NetworkConfigPlcState();
}

class NetworkConfigPlcState extends State<NetworkConfigPlc> {
  StyleUtils _styleUtils = StyleUtils();

  /// Tcp 地址数据列表
  List<PlcBean> _tcpList = [];

  @override
  initState() {
    super.initState();
    NetworkInterface.list().then((list) {
      setState(() {
        // this.tcpList.clear();
        if (null == list || 0 == list.length) return;
        list.forEach((item) {
          // 2022-08-16 after
          item.addresses.forEach((address) {
            PlcBean bean = PlcBean();
            bean.ip = '${address.address}';
            bean.name = item.name;
            bean.port = 8888;
            this._tcpList.add(bean);
          });
          // 2022-08-16 before
          // PlcBean bean = PlcBean();
          // bean.name = item.name;
          // item.addresses.forEach((address) {
          //   bean.ip += '${address.address}';
          // });
          // bean.port = 8888;
          // this._tcpList.add(bean);
        });
      });
    });
  }

  /// 切换，未连接-直接连接，已连接-同一个-断开连接，已连接-非同一个-断开后再连接
  /// [bean]
  void _changed(PlcBean bean) {
    CoolKeyboard.hideKeyboard();
    Timer(Duration(milliseconds: 600), () {
      setState(() {
        PlcBean curr = PlcTcpUtils.instance.mPlcBean;
        if (null != curr) {
          PlcTcpUtils.instance.stop();
          if (curr.ip == bean.ip) return;
        }
        PlcTcpUtils.instance.mPlcBean = bean;
        PlcTcpUtils.instance.bind(bean.ip, bean.port);
      });
    });
  }

  /// 判断当前的 TcpBean 是否已连接
  bool _check(PlcBean plcBean) {
    PlcBean curr = PlcTcpUtils.instance.mPlcBean;
    return null != curr && curr.ip == plcBean.ip;
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
            '网关信息',
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
                alignment: Alignment.center,
                width: width,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: 80,
                      height: 50,
                      child: Text(
                        '网口',
                        textAlign: TextAlign.center,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                      // decoration: BoxDecoration(color: Colors.grey),
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: width - 280,
                      height: 50,
                      child: Text(
                        'IP',
                        textAlign: TextAlign.center,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: 60,
                      height: 50,
                      child: Text(
                        '端口',
                        textAlign: TextAlign.center,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: 140,
                      height: 50,
                      child: Text(
                        '状态',
                        textAlign: TextAlign.center,
                        style: _styleUtils.textStyle(14, 0),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: width,
                height: height - 100,
                child: ListView.builder(
                  itemCount: _tcpList.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    PlcBean plcBean = this._tcpList[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          width: 80,
                          height: 50,
                          child: Text(
                            plcBean.name,
                            textAlign: TextAlign.center,
                            style: _styleUtils.textStyle(14, 1),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: width - 280,
                          height: 50,
                          child: Text(
                            plcBean.ip,
                            textAlign: TextAlign.center,
                            style: _styleUtils.textStyle(14, 1),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: 60,
                          height: 50,
                          child: Text(
                            '${plcBean.port}',
                            textAlign: TextAlign.center,
                            style: _styleUtils.textStyle(14, 1),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 5,
                            bottom: 5,
                          ),
                          alignment: Alignment.center,
                          width: 110,
                          height: 40,
                          child: _styleUtils.connect(0, _check(plcBean), () {
                            this._changed(plcBean);
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
