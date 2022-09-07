import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/db/DbUtils.dart';
import 'package:myapp/utils/socket/GnsTcpUtils.dart';
import 'package:myapp/utils/socket/PlcTcpUtils.dart';

/// 初始化工具类
/// Created in 2021-08-24 21:51:44 by YinRH
class InitMgrUtils {
  /// 绑定 Plc 网关，默认绑定第一个
  void plc() {
    PlcBean plcBean = PlcTcpUtils.instance.mPlcBean;
    if (null != plcBean) return; // 已连接
    NetworkInterface.list().then((list) {
      if (this._isEmpty(list)) return;
      // list.forEach((item) {
      //   item.addresses.forEach((e) {
      //     String _address = e.address;
      //     if ('172.16.1.252' == _address) {
      //       PlcBean bean = PlcBean();
      //       bean.name = item.name;
      //       bean.ip = _address;
      //       bean.port = 8888;
      //       PlcTcpUtils.instance.mPlcBean = bean;
      //       PlcTcpUtils.instance.bind(bean.ip, bean.port);
      //     }
      //   });
      // });

      NetworkInterface net = list[0];
      List<InternetAddress> _ipList = net.addresses;
      if (this._isEmpty(_ipList)) return;
      InternetAddress _address = _ipList[0];
      PlcBean bean = PlcBean();
      bean.name = net.name;
      bean.ip = '${_address.address}';
      bean.port = 8888;
      PlcTcpUtils.instance.mPlcBean = bean;
      PlcTcpUtils.instance.bind(bean.ip, bean.port);
    });
  }

  /// 判断字符串/数组是否为 null 或 0-length
  bool _isEmpty(dynamic value) {
    return null == value || 0 == value.length;
  }

  /// 连接 Gns 网络
  void gns(BuildContext context) {
    DbUtils.instance.add(
      DbBean(
        type: 0,
        cb: (GnsBean bean) => _gnsCb(context, bean),
      ),
    );
  }

  /// 处理 Gns 结果
  void _gnsCb(BuildContext context, GnsBean bean) {
    if (_isEmpty(bean.ip) || _isEmpty(bean.port)) {
      // print('请配置 Gns 传感网络地址和端口');
      // Timer(Duration(seconds: 10), () {
      //   showDialog(
      //     barrierDismissible: false,
      //     context: context,
      //     builder: (ctx) {
      //       return KeyboardRootWidget(
      //         child: NetworkConfigDialog(),
      //       );
      //     },
      //   );
      // });
      return;
    }
    GnsTcpUtils.instance.connect(bean.ip, bean.port);
  }
}
