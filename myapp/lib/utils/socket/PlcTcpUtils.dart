import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/socket/GnsTcpUtils.dart';

/// 数据流控制器
// final mStreamControllerCmds = StreamController.broadcast(); // 指令区域
// final mStreamControllerList = StreamController.broadcast(); // 列表-风机状态/维度仪表/色谱仪
// final mStreamControllerWdyl = StreamController.broadcast(); // 温度/压力-细/粗管阀
// final mStreamControllerHjbj = StreamController.broadcast(); // 报警器-环境
// final mStreamControllerKrqt = StreamController.broadcast(); // 报警器-可燃气体
// final mStreamControllerCgfm = StreamController.broadcast(); // 状态-粗管阀
// final mStreamControllerGnfj = StreamController.broadcast(); // 状态-柜内风机
final mStreamControllerUI = StreamController.broadcast();

/// PLC网络 Socket 工具类
/// Created in 2021-08-19 09:12:54 by YinRH
class PlcTcpUtils {
  factory PlcTcpUtils() => _getInstance();
  static PlcTcpUtils get instance => _getInstance();
  static PlcTcpUtils _instance;

  PlcTcpUtils._internal() {
    //  初始化数据
    // DateTime dt = new DateTime.now();
    // this.mTimeFan = dt.millisecondsSinceEpoch;
  }

  static PlcTcpUtils _getInstance() {
    if (null == _instance) {
      _instance = new PlcTcpUtils._internal();
    }
    return _instance;
  }

  Map<String, Client> _mMapClient = Map<String, Client>(); // 套接字
  ServerSocket _mServerSocket; // 服务端Socket
  // String _mCmdMsg; // 指令内容
  PlcBean mPlcBean; // 当前连接的 PlcBean 对象
  int _mPlcTime = 0; // 更新开始的时间
  GnsData _mGnsData = GnsData(); // 更新重组的数据
  // Wdyl wdylC = Wdyl(), wdylX = Wdyl(); // 粗/细管阀温度/压力

  /// 停止 ServerSocket
  void stop() {
    if (null != this._mServerSocket) {
      if (null != _mMapClient) {
        Iterable<String> keys = _mMapClient.keys;
        if (null != keys) {
          keys.forEach((item) {
            _mMapClient[item].mSocket.close();
          });
          keys = null;
        }
        this._mMapClient.clear();
      }
      this._mServerSocket.close();
      this.mPlcBean = null;
      this._mServerSocket = null;
    } else {
      this.mPlcBean = null;
      if (null != _mMapClient) _mMapClient.clear();
    }
  }

  /// 绑定 ServerSocket
  /// [ip] IP地址，[port] 端口
  void bind(String ip, int port) async {
    if (null != this._mServerSocket) return; // 已绑定
    _mServerSocket = await ServerSocket.bind(ip, port);
    // 遍历 Socket，进行 Stream 监听，并进行数据处理
    await for (Socket socket in _mServerSocket) {
      // print('1111111111222222222222');
      Client current;
      if (_mMapClient.containsKey(socket.address.address)) {
        current = _mMapClient[socket.address.address];
        current.mSocket = socket;
      } else {
        current = new Client();
        current.mAddress = socket.address.address;
        current.mSocket = socket;
        current.mCache = [];
        _mMapClient[socket.address.address] = current;
      }
      // 监听 Stream，并处理数据
      current.mSocket.listen((data) => parseData(data));
    }
  }

  /// 处理数据
  /// 遍历数据，数据格式： 0x86 + LEN + DATA + 0x68
  /// LEN：1字节，DATA：len个字节(1个字节类型，len-1字节个数据)
  void parseData(Uint8List data) {
    // print('111222333: $data');
    int total = data.length;
    for (int i = 0; i < total; i++) {
      // 必须是0x86开始，且长度必须大于3个字节，等于3表示无数据
      if (data[i] != 0x86 || total <= 3) continue;
      // 判断有效数据长度，以及是0x68结束
      int len = data[i + 1]; // 数据的长度
      int j = i + 2 + len;
      if ((total < j + 1) || data[j] != 0x68) continue;
      // 处理数据
      this._parseOb(data.sublist(i, j + 1));
      i = j + 1;
    }
  }

  /// 处理 Cache 数据
  /// [p] 有效数据
  void _parseOb(Uint8List p) {
    switch (p[2]) {
      // case 1: // 风机状态
      //   PlcData plcData1 = PlcData();
      //   ObFan obFan = ObFan();
      //   obFan.tempFront = parseDouble(p, 3, 7);
      //   obFan.tempAfter = parseDouble(p, 7, 11);
      //   obFan.shockFront = parseDouble(p, 11, 15);
      //   obFan.shockAfter = parseDouble(p, 15, 19);
      //   obFan.output = parseDouble(p, 19, 23);
      //   obFan.runSpeed = parseDouble(p, 23, 27);
      //   obFan.runRate = parseDouble(p, 27, 31);
      //   obFan.setRate = parseDouble(p, 31, 35);
      //   obFan.inVal = parseDouble(p, 35, 39);
      //   obFan.inValFeed = parseDouble(p, 39, 43);
      //   obFan.runShow = parseDouble(p, 43, 47);
      //   obFan.alarm = parseDouble(p, 47, 51);
      //   obFan.ventOpen = parseDouble(p, 51, 55);
      //   obFan.ventClose = parseDouble(p, 55, 59);
      //   obFan.alarmRest = parseDouble(p, 59, 63);
      //   obFan.local = parseDouble(p, 63, 67);
      //   obFan.control = parseDouble(p, 67, 71);
      //   plcData1.type = 1;
      //   plcData1.ob = obFan;
      //   GnsTcpUtils.instance.package(plcData1);
      //   break;
      case 2: // DN100回路阀门状态
        PlcData plcData2 = PlcData();
        ObCrudeSTA obCrudeSTA = ObCrudeSTA();
        obCrudeSTA.crudeVal = _parseDouble(p, 3, 7);
        plcData2.type = 2;
        plcData2.ob = obCrudeSTA;
        this.updatePlcDataToUI(plcData2);
        GnsTcpUtils.instance.package(plcData2);
        break;
      case 3: // 防爆风机
        PlcData plcData3 = PlcData();
        ObFineSTA obFineSTA = ObFineSTA();
        obFineSTA.fineVal = _parseDouble(p, 3, 7);
        plcData3.type = 3;
        plcData3.ob = obFineSTA;
        this.updatePlcDataToUI(plcData3);
        GnsTcpUtils.instance.package(plcData3);
        break;
      // case 4: //维度仪表流量计
      //   PlcData plcData4 = PlcData();
      //   ObFlowWdyb obFlowWdyb = ObFlowWdyb();
      //   double sc1 = parseDouble(p, 3, 7) * 10000;
      //   double sc2 = parseDouble(p, 7, 11) / 1000;
      //   String tmp = (sc1 + sc2).toStringAsFixed(4);
      //   obFlowWdyb.totalSC01 = double.parse(tmp);
      //   obFlowWdyb.totalSC02 = 0.00;
      //   obFlowWdyb.streamSC = parseDouble(p, 11, 15);
      //   obFlowWdyb.streamWC = parseDouble(p, 15, 19);
      //   obFlowWdyb.realPre = parseDouble(p, 19, 23);
      //   obFlowWdyb.realTem = parseDouble(p, 23, 27);
      //   double wc1 = parseDouble(p, 27, 31) * 10000;
      //   double wc2 = parseDouble(p, 31, 35) / 1000;
      //   String res = (wc1 + wc2).toStringAsFixed(4);
      //   obFlowWdyb.totalWC01 = double.parse(res);
      //   obFlowWdyb.totalWC02 = 0.0000;
      //   obFlowWdyb.battery = parseDouble(p, 35, 39);
      //   plcData4.type = 4;
      //   plcData4.ob = obFlowWdyb;
      //   GnsTcpUtils.instance.package(plcData4);
      //   break;
      case 5: // 西客流量计
        PlcData plcData5 = PlcData();
        ObFlowXmz obFlowXmz = ObFlowXmz();
        obFlowXmz.ssFlow = _parseDouble(p, 3, 7);
        obFlowXmz.ljFlow = _parseDouble(p, 7, 11);
        obFlowXmz.tem = _parseDouble(p, 11, 15);
        obFlowXmz.pre = _parseRate(p, 15, 19, 100);
        obFlowXmz.ssFlowBk = _parseDouble(p, 19, 23);
        obFlowXmz.ljFlowBk = _parseDouble(p, 23, 27);
        plcData5.type = 5;
        plcData5.ob = obFlowXmz;
        this.updatePlcDataToUI(plcData5);
        GnsTcpUtils.instance.package(plcData5);
        break;
      // case 6: // 细管阀温度
      //   PlcData plcData6 = PlcData();
      //   ObFineTEM obFineTEM = ObFineTEM();
      //   obFineTEM.fineTem = parseDouble(p, 3, 7);
      //   plcData6.type = 6;
      //   plcData6.ob = obFineTEM;
      //   wdylX.type = 67;
      //   wdylX.tem = plcData6;
      //   GnsTcpUtils.instance.package(plcData6);
      //   break;
      // case 7: // 细管阀压力
      //   PlcData plcData7 = PlcData();
      //   ObFinePRE obFinePRE = ObFinePRE();
      //   obFinePRE.finePre = parseRate(p, 3, 7, 1000);
      //   plcData7.type = 7;
      //   plcData7.ob = obFinePRE;
      //   wdylX.type = 67;
      //   wdylX.pre = plcData7;
      //   GnsTcpUtils.instance.package(plcData7);
      //   break;
      case 8: // 西门子色谱仪
        PlcData plcData8 = PlcData();
        ObSpy obSpy = ObSpy();
        obSpy.n2 = _parseDouble(p, 3, 7);
        obSpy.ch4 = _parseDouble(p, 7, 11);
        obSpy.co2 = _parseDouble(p, 11, 15);
        obSpy.c2h6 = _parseDouble(p, 15, 19);
        obSpy.c3h8 = _parseDouble(p, 19, 23);
        obSpy.c4h10iso = _parseDouble(p, 23, 27);
        obSpy.c4h10n = _parseDouble(p, 27, 31);
        obSpy.c5h12neo = _parseDouble(p, 31, 35);
        obSpy.c5h12iso = _parseDouble(p, 35, 39);
        obSpy.c5h12n = _parseDouble(p, 39, 43);
        obSpy.c6p = _parseDouble(p, 43, 47);
        obSpy.nsTotal = _parseDouble(p, 47, 51);
        obSpy.sn2 = _parseDouble(p, 51, 55);
        obSpy.sch4 = _parseDouble(p, 55, 59);
        obSpy.sco2 = _parseDouble(p, 59, 63);
        obSpy.sc2h6 = _parseDouble(p, 63, 67);
        obSpy.sc3h8 = _parseDouble(p, 67, 71);
        obSpy.sc4h10iso = _parseDouble(p, 71, 75);
        obSpy.sc4h10n = _parseDouble(p, 75, 79);
        obSpy.sc5h12neo = _parseDouble(p, 79, 83);
        obSpy.sc5h12iso = _parseDouble(p, 83, 87);
        obSpy.sc5h12n = _parseDouble(p, 87, 91);
        obSpy.sc6p = _parseDouble(p, 91, 95);
        obSpy.tHeatMass = _parseDouble(p, 95, 99);
        obSpy.nHeatMass = _parseDouble(p, 99, 103);
        obSpy.tHeatVol = _parseDouble(p, 103, 107);
        obSpy.nHeatVol = _parseDouble(p, 107, 111);
        obSpy.sumFactor = _parseDouble(p, 111, 115);
        obSpy.moWeight = _parseDouble(p, 115, 119);
        obSpy.density = _parseDouble(p, 119, 123);
        obSpy.densityRel = _parseDouble(p, 123, 127);
        obSpy.wobbeTotal = _parseDouble(p, 127, 131);
        obSpy.wobbeNet = _parseDouble(p, 131, 135);
        obSpy.spare = _parseDouble(p, 135, 139);
        plcData8.type = 8;
        plcData8.ob = obSpy;
        this.updatePlcDataToUI(plcData8);
        GnsTcpUtils.instance.package(plcData8);
        break;
      case 9: // 可燃气体报警器
        PlcData plcData9 = PlcData();
        ObAlarmGas obAlarmGas = ObAlarmGas();
        obAlarmGas.alarmGas = _parseDouble(p, 3, 7);
        obAlarmGas.h2Gas = _parseDouble(p, 7, 11);
        obAlarmGas.ch4Gas = _parseDouble(p, 11, 15);
        plcData9.type = 9;
        plcData9.ob = obAlarmGas;
        this.updatePlcDataToUI(plcData9);
        GnsTcpUtils.instance.package(plcData9);
        break;
      // case 10: // 报警器
      //   PlcData plcData10 = PlcData();
      //   ObAlarm obAlarm = ObAlarm();
      //   obAlarm.alarm = parseDouble(p, 3, 7);
      //   plcData10.type = 10;
      //   plcData10.ob = obAlarm;
      //   this.updatePlcDataToUI(plcData10);
      //   GnsTcpUtils.instance.package(plcData10);
      //   break;
    }
  }

  /// 重组数据更新页面
  void updatePlcDataToUI(PlcData plcData) {
    DateTime dt = DateTime.now();
    switch (plcData.type) {
      case 2: // DN100回路阀门状态
        ObCrudeSTA cgzt = plcData.ob as ObCrudeSTA;
        this._mGnsData.obCrudeSTA = cgzt;
        break;
      case 3: // 防爆风机
        ObFineSTA xgzt = plcData.ob as ObFineSTA;
        this._mGnsData.obFineSTA = xgzt;
        break;
      case 5: // 西客流量计
        ObFlowXmz xmz = plcData.ob as ObFlowXmz;
        this._mGnsData.obFlowXmz = xmz;
        break;
      case 8: // 西门子色谱仪
        ObSpy spy = plcData.ob as ObSpy;
        this._mGnsData.obSpy = spy;
        break;
      case 9: // 可燃气体报警器
        ObAlarmGas qtbj = plcData.ob as ObAlarmGas;
        this._mGnsData.obAlarmGas = qtbj;
        break;
      case 13: // 天燃气能量
        ObEnergy trqnl = plcData.ob as ObEnergy;
        this._mGnsData.obEnergy = trqnl;
        break;
    }
    int time = dt.millisecondsSinceEpoch;
    if (time - this._mPlcTime >= 5000) {
      this._mPlcTime = time;
      // print('time: ${dt.toString()}');
      mStreamControllerUI.add(this._mGnsData);
    }
  }

  /// 转换成 double 类型数据
  /// [p] 有效数据，[start] 开始索引值，[end] 结束索引值
  double _parseDouble(Uint8List p, int start, int end) {
    double res = Uint8List.fromList(p.sublist(start, end).reversed.toList())
        .buffer
        .asFloat32List()
        .toList()[0];
    return double.parse(res.toStringAsFixed(4));
  }

  /// 转换成 double 类型数据
  /// [p] 有效数据，[start] 开始索引值，[end] 结束索引值，[rate] 倍率
  double _parseRate(Uint8List p, int start, int end, int rate) {
    double res = Uint8List.fromList(p.sublist(start, end).reversed.toList())
        .buffer
        .asFloat32List()
        .toList()[0];
    return double.parse((res * rate).toStringAsFixed(4));
  }

  /// 发送指令
  /// [cmd] 指令，[cb] 回调
  void send(String cmd, Function cb) {
    try {
      print(DateTime.now().toString() + ' : $cmd');
      List<int> list = Utf8Encoder().convert(cmd);
      this._mMapClient[mPlcBean.ip].mSocket.add(list);
    } catch (e) {}
  }
}

class Client {
  String mAddress; // IP地址
  Socket mSocket; // 套接字
  List<int> mCache; // 数据
}
