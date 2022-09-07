import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/socket/PlcTcpUtils.dart';

/// 传感网络 Socket 工具类
/// Created in 2021-08-19 08:43:44 by YinRH
class GnsTcpUtils {
  factory GnsTcpUtils() => _getInstance();
  static GnsTcpUtils get instance => _getInstance();
  static GnsTcpUtils _instance;

  GnsTcpUtils._internal() {
    this._mHasRequest = false;
    this._mHasClose = false;
    this.mHasConnect = false;
  }

  // int _isend = 0;
  // int _ireceive = 0;

  static GnsTcpUtils _getInstance() {
    if (null == _instance) {
      _instance = new GnsTcpUtils._internal();
    }
    return _instance;
  }

  Socket _mSocket; // Socket套接字
  String _mIp; // IP地址
  int _mPort; // 端口
  // Function mSocketCB; // 回调方法
  bool _mHasRequest = false; // 是否在请求连接
  bool mHasConnect = false; // 是否已连接GNS
  bool _mHasClose = false; // 是否已断开GNS
  Function _mUpgrade; // 连接状态的回调方法
  int _mGnsTime = 0; // 上报开始时间
  GnsData _mGnsData = GnsData(); // 上报重组的数据
  int _qcInterval = 2; // 上报间隔时间，默认两秒
  // 重新连接计时器
  Timer _timer;

  /// 设置回调
  /// [cb] 回调方法，prepare-准备，success-成功，failure-失败
  // void cb(Function cb) {
  //   this.mSocketCB = cb;
  // }

  /// 设置地址，包括 IP 和 Port
  /// [ip] 传感网络地址，[port] 传感网络端口
  // void address(String ip, int port) {
  //   this.mIp = ip;
  //   this.mPort = port;
  // }

  /// 更新当前 Gns 传感网络的连接状态
  void upgrade(Function cb) {
    this._mUpgrade = cb;
  }

  /// 切换连接状态
  /// [hasConnect] true-已连接
  void changed(bool hasConnect) {
    if (hasConnect) {
      close();
    } else {
      connect(_mIp, _mPort.toString());
    }
  }

  /// 关闭 Socket 连接
  void close() {
    if (_mSocket == null) return;
    _mSocket.close();
    this._mSocket = null;
    this._mHasClose = true;
  }

  /// 连接 Socket
  void connect(String ip, String port) {
    // 已连接，不再重复发送连接请求
    if (this.mHasConnect) return;
    // 更新数据
    this._mPort = int.parse(port);
    this._mIp = ip;
    this._mHasClose = false;
    // 是否正在请求连接中
    if (!_mHasRequest) _reconnect();
    this._mHasRequest = true;
  }

  /// 重连 Socket
  void _reconnect() {
    if (null == this._mIp || null == this._mPort) {
      this._mHasRequest = false;
      // if (null != mSocketCB) mSocketCB('prepare');
      return;
    }
    Socket.connect(_mIp, _mPort).then((Socket so) {
      if (_timer != null) _timer.cancel();
      // if (null != mSocketCB) mSocketCB('success');
      if (null != _mUpgrade) _mUpgrade(true);
      this.mHasConnect = true;
      this._mHasRequest = false;
      this._mSocket = so;
      DateTime dt = DateTime.now();
      _mGnsTime = dt.millisecondsSinceEpoch;
      this._listen(so.asBroadcastStream()); // 订阅
    }).catchError((error) {
      print('GnsTcpUtils.connect.onError: $error');
      this._dealErrorAndTryConnect();
    });
  }

  /// 监听 Socket
  /// [stream] 多次订阅的流
  void _listen(Stream<Uint8List> stream) {
    if (null == stream) return;
    stream.listen((data) {
      this._dealResultAndCmd(data);
    }, onDone: () {
      this._dealErrorAndTryConnect();
    }, onError: (error) {
      this._dealErrorAndTryConnect();
    });
  }

  /// 处理应答数据或指令
  void _dealResultAndCmd(Uint8List result) {
    String res = String.fromCharCodes(result);
    // print("gns回传来数据解析 res: $res");
    int total = null == res ? 0 : res.length;
    // print('resp: $res');
    for (int i = 0; i < total; i++) {
      if (i + 2 >= total) break;
      String head = res.substring(i, i + 2);
      if ('86' != head) continue; // 非86开头
      if (total - i <= 8) continue; // 长度不对
      // 从 ℹ + 2 开始的 4 位是长度值
      String l = res.substring(i + 2, i + 6);
      if (RegExp(r"^[A-Fa-f0-9]+$").hasMatch(l)) {
        int len = int.parse(l, radix: 16);
        int j = i + 6 + len;
        if (total < j + 2) continue; // 长度不对
        String foot = res.substring(j, j + 2);
        if ('68' != foot) continue;
        // 获取有效的 json 字符串
        String r = res.substring(i + 6, j);
        // print(DateTime.now().toString() + ': $r');
        Map<String, dynamic> map = jsonDecode(r);
        ResBean resBean = ResBean.fromJson(map);
        this._dealCmdForReportGnsOrSendPlc(resBean);
        // 继续循环
        i = j + 2;
      }
    }
    // try {
    // Uint8List temp = Uint8List.fromList(data);
    // String r = String.fromCharCodes(temp);
    // print(DateTime.now().toString() + ': $r');
    // Map<String, dynamic> map = jsonDecode(r);
    // ResBean resBean = ResBean.fromJson(map);
    // this.dealCmdForReportGnsOrSendPlc(resBean);
    // } catch (e) {}
  }

  /// 处解Gns下发的指令并发送到Plc
  void _dealCmdForReportGnsOrSendPlc(ResBean resBean) {
    if (200 != resBean.code) return; // 异常
    ResData rd = resBean.data;
    if (null == rd) return;

    switch (rd.type) {
      case 0:
        ResEnergy energy = rd.energy;
        ObEnergy obEnergy = ObEnergy();
        obEnergy.qcEnergy = energy.qcEnergy;
        obEnergy.qcMassCalorific = energy.qcMassCalorific;
        obEnergy.qcMolar = energy.qcMolar;
        obEnergy.qcVolumeCalorific = energy.qcVolumeCalorific;
        obEnergy.qcInterval = energy.qcInterval;
        _qcInterval = energy.qcInterval;
        PlcData plcData13 = PlcData();
        plcData13.type = 13;
        plcData13.ob = obEnergy;
        // print("gns receive data(${_ireceive}) :${json.encode(obEnergy)}");
        // _ireceive += 1;
        PlcTcpUtils.instance.updatePlcDataToUI(plcData13);
        break;
      case 1:
        String cmd = rd.text; // 下发的指令
        if (null != cmd && 0 != cmd.length) {
          PlcTcpUtils.instance.send(cmd, () {});
        }
        break;
    }

    // EasyLoading.showError('计量云平台下发的指令为空');
  }

  /// Socket 异常或错误时，重新连接
  void _dealErrorAndTryConnect() {
    if (_timer != null) _timer.cancel();
    if (null != _mUpgrade) _mUpgrade(false);
    this.mHasConnect = false;
    this._mHasRequest = false;
    this._mSocket = null;
    _timer = Timer(const Duration(seconds: 10), () {
      if (!_mHasClose) this._reconnect();
    });
    // if (null != mSocketCB) mSocketCB('failure');
  }

  /// 重组数据
  void package(PlcData plcData) {
    DateTime dt = DateTime.now();
    String date = dt.toString().substring(0, 19);
    switch (plcData.type) {
      // case 1: // 风机状态
      //   ObFan fjzt = plcData.ob as ObFan;
      //   fjzt.site = '秦川';
      //   fjzt.time = date;
      //   this.mGnsData.obFan = fjzt;
      //   break;
      case 2: // DN100回路阀门状态
        ObCrudeSTA cgzt = plcData.ob as ObCrudeSTA;
        cgzt.site = '秦川';
        cgzt.loop = '回路1';
        cgzt.time = date;
        this._mGnsData.obCrudeSTA = cgzt;
        break;
      case 3: // 防爆风机
        ObFineSTA xgzt = plcData.ob as ObFineSTA;
        xgzt.site = '秦川';
        xgzt.loop = '回路2';
        xgzt.time = date;
        this._mGnsData.obFineSTA = xgzt;
        break;
      // case 4: // 流量计-维度仪表
      //   ObFlowWdyb wdyb = plcData.ob as ObFlowWdyb;
      //   wdyb.site = '秦川';
      //   wdyb.loop = '回路2';
      //   wdyb.time = date;
      //   this.mGnsData.obFlowWdyb = wdyb;
      //   break;
      case 5: // 西客流量计
        ObFlowXmz xmz = plcData.ob as ObFlowXmz;
        xmz.site = '秦川';
        xmz.loop = '回路1';
        xmz.time = date;
        this._mGnsData.obFlowXmz = xmz;
        // ObCrudeTEM cgwd = ObCrudeTEM();
        // cgwd.time = date;
        // cgwd.crudeTem = xmz.tem;
        // this.mGnsData.obCrudeTEM = cgwd;
        // ObCrudePRE cgyl = ObCrudePRE();
        // cgyl.time = date;
        // cgyl.crudePre = xmz.pre;
        // this.mGnsData.obCrudePRE = cgyl;
        break;
      // case 6: // 细管温度
      //   ObFineTEM xgwd = plcData.ob as ObFineTEM;
      //   xgwd.time = date;
      //   this.mGnsData.obFineTEM = xgwd;
      //   break;
      // case 7: // 细管压力
      //   ObFinePRE xgyl = plcData.ob as ObFinePRE;
      //   xgyl.time = date;
      //   this.mGnsData.obFinePRE = xgyl;
      //   break;
      case 8: // 西门子色谱仪
        ObSpy spy = plcData.ob as ObSpy;
        spy.time = date;
        if (65535.0 == spy.n2) break;
        this._mGnsData.obSpy = spy;
        break;
      case 9: // 可燃气体报警器
        ObAlarmGas qtbj = plcData.ob as ObAlarmGas;
        qtbj.site = '秦川';
        qtbj.time = date;
        this._mGnsData.obAlarmGas = qtbj;
        break;
      // case 10: // 报警器
      //   ObAlarm wbbj = plcData.ob as ObAlarm;
      //   wbbj.site = '秦川';
      //   wbbj.time = date;
      //   this.mGnsData.obAlarm = wbbj;
      //   break;
    }
    int time = dt.millisecondsSinceEpoch;
    if (time - this._mGnsTime >= _qcInterval * 1000) {
      this._mGnsTime = time;
      if (null == _mSocket) return;
      List<int> data = this._formatObj(this._mGnsData);
      int length = data.length;
      List<int> _len = this._formatInt(length, 4);
      List<int> head = this._formatInt(134, 2); // 0x86
      List<int> foot = this._formatInt(104, 2); // 0x68

      _mSocket.add([...head, ..._len, ...data, ...foot]);
    }
  }

  /// 将Bean对象转成List<int>
  List<int> _formatObj(GnsData gnsData) {
    String data = jsonEncode(gnsData);
    // print("gns send data : ${data}");
    // _isend += 1;
    return Utf8Encoder().convert(data);
  }

  /// 将int对象转成制定宽度的List<int>
  List<int> _formatInt(int number, int width) {
    String data = number.toRadixString(16);
    data = data.padLeft(width, '0');
    return Utf8Encoder().convert(data);
  }
}
