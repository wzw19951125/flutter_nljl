import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/pages/work/WorkControlTitle.dart';
import 'package:myapp/utils/bean/Bean.dart';
import 'package:myapp/utils/init/InitMgrUtils.dart';
import 'package:myapp/utils/socket/GnsTcpUtils.dart';
import 'package:myapp/utils/socket/PlcTcpUtils.dart';
import 'package:myapp/utils/style/StyleUtils.dart';

/// 工控屏
/// Created in 2021-08-18 14:43:44 by YinRH
/// left top to bottom:9 2 3
/// right top to bottom:5 8 13
class WorkControlPage extends StatefulWidget {
  @override
  WorkControlState createState() => WorkControlState();
}

class WorkControlState extends State<WorkControlPage> {
  InitMgrUtils _mInitMgrUtils = InitMgrUtils();
  StyleUtils _styleUtils = StyleUtils();
  // double _arams = 0.0; // 报警器
  double _h2Gas = 0.0; //报警器-氢气
  double _ch4Gas = 0.0; //报警器-甲烷
  double _aramsGas = 0.0; // 报警器-可燃气体
  double _statusCgf = 3.0; // 粗管阀状态，1.0-开单位，2.0-关到位
  double _statusGnfj = 3.0; // 柜内风机状态
  ObSpy _obSpy = ObSpy(); // 色谱仪
  ObFlowXmz _flowXmz = ObFlowXmz(); // 西门子流量计
  ObEnergy _energy = ObEnergy(); // 热量

  WorkControlState() {
    _mInitMgrUtils.plc(); // 绑定 PLC 网关
  }

  @override
  void initState() {
    super.initState();
    _mInitMgrUtils.gns(context); // 连接 GNS 网络
    mStreamControllerUI.stream.listen((event) {
      setState(() {
        GnsData gnsData = event as GnsData;
        // 可燃气体报警器
        ObAlarmGas krqt = gnsData.obAlarmGas;
        this._aramsGas = null == krqt ? 0.0 : krqt.alarmGas;
        this._h2Gas = null == krqt ? 0.0 : krqt.h2Gas;
        this._ch4Gas = null == krqt ? 0.0 : krqt.ch4Gas;
        // DN100回路阀门状态
        ObCrudeSTA cgf = gnsData.obCrudeSTA;
        this._statusCgf = null == cgf ? 3.0 : cgf.crudeVal;
        // 防爆风机
        ObFineSTA fj = gnsData.obFineSTA;
        this._statusGnfj = null == fj ? 3.0 : fj.fineVal;
        // 西客流量计
        ObFlowXmz xmz = gnsData.obFlowXmz;
        this._flowXmz = null == xmz ? ObFlowXmz() : xmz;
        // 西门子色谱仪
        ObSpy spy = gnsData.obSpy;
        this._obSpy = null == spy ? ObSpy() : spy;
        // 天燃气能量(gns)
        ObEnergy energy = gnsData.obEnergy;
        this._energy = null == energy ? ObEnergy() : energy;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    GnsTcpUtils.instance.close();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; // 屏幕的尺寸
    double tHeight = 60; // TitleBar的高度
    double width = size.width;
    double height = size.height - tHeight;
    double width1 = (width - 30) * 0.3 - 0.1;
    double height1 = height - 0.1 - 10 * 6;
    double width2 = (width - 30) * 0.7 - 0.1;
    double height2 = height - 0.1 - 10 * 4;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/bg_workcontrol.png'),
          fit: BoxFit.fill,
        ),
      ),
      width: width,
      height: size.height,
      child: Column(
        children: [
          // 标题栏
          Container(
            width: width,
            height: tHeight,
            child: WorkControlTitle(
              size: Size(width, tHeight),
            ),
          ),
          // 功能区
          Container(
            alignment: Alignment.center,
            width: width,
            height: height,
            child: Row(
              children: [
                Container(width: 10, height: 10),
                Container(
                  alignment: Alignment.center,
                  width: width1,
                  height: height - 0.1,
                  child: Column(
                    children: [
                      this._buildWarningBar(
                        title: '管道侧可燃性气体报警器',
                        valve: _aramsGas,
                        width: width1,
                        height: height1 * 0.16,
                      ),
                      Container(width: 10, height: 10),
                      this._buildWarningBar(
                        title: '网关侧氢气报警器',
                        valve: this._h2Gas,
                        width: width1,
                        height: height1 * 0.16,
                      ),
                      Container(width: 10, height: 10),
                      this._buildWarningBar(
                        title: '网关侧甲烷报警器',
                        valve: this._ch4Gas,
                        width: width1,
                        height: height1 * 0.16,
                      ),
                      Container(width: 10, height: 10),
                      this._buildValveStatus(
                        title: 'DN100回路阀门状态',
                        valve: this._statusCgf,
                        isCgf: true,
                        width: width1,
                        height: height1 * 0.18,
                      ),
                      Container(width: 10, height: 10),
                      this._buildValveStatus(
                        title: '防爆排风机',
                        valve: this._statusGnfj,
                        isCgf: false,
                        width: width1,
                        height: height1 * 0.18,
                      ),
                      Container(width: 10, height: 10),
                      this._buildValveControl(
                        title: 'DN100回路阀门控制',
                        width: width1,
                        height: height1 * 0.16,
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Container(width: 10, height: 10),
                Container(
                  alignment: Alignment.center,
                  width: width2,
                  height: height - 0.1,
                  child: Column(
                    children: [
                      this._buildFlowXmz(
                        title: '天然气流量信息感知',
                        width: width2,
                        height: height1 * 0.16,
                      ),
                      Container(width: 10, height: 10),
                      this._buildSepuyi(
                        title: '天然气组分信息感知',
                        width: width2,
                        height: height2 - height1 * 0.305,
                      ),
                      Container(width: 10, height: 10),
                      this._buildDataGns(
                        title: '天然气能量信息感知',
                        width: width2,
                        height: height1 * 0.16,
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Container(width: 10, height: 10),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  /// 报警器（含进度条）,title-名称，valve-阀值
  Widget _buildWarningBar({
    String title = '',
    double valve = 0.0,
    double width = 0,
    double height = 0,
  }) {
    final double myVal = null == valve
        ? 0.0
        : valve < 0.0
            ? 0.0
            : valve > 100.0
                ? 100.0
                : valve;
    final int myInt = myVal ~/ 5;
    List<String> list = [];
    for (int i = 1; i <= 20; i++) {
      if (i >= 1 && i <= 5 && i <= myInt) {
        list.add('images/icon_seek_green.png');
      } else if (i > 5 && i <= 10 && i <= myInt) {
        list.add('images/icon_seek_yellow.png');
      } else if (i > 10 && i <= 20 && i <= myInt) {
        list.add('images/icon_seek_red.png');
      } else {
        list.add('images/icon_seek_write.png');
      }
    }
    final myRes = myVal ~/ 1;
    return Container(
      decoration: this._styleUtils.radius(6, 10),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          // 名称
          Container(
            alignment: Alignment.center,
            width: width,
            height: height / 3,
            child: Text(
              title,
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          // 进度条
          Container(
            alignment: Alignment.center,
            width: width,
            height: height / 3,
            child: Row(
              children: [
                ...list.map((e) {
                  return Container(
                    alignment: Alignment.center,
                    width: 11,
                    height: 16,
                    child: Image.asset(
                      e,
                      fit: BoxFit.fill,
                      width: 11,
                      height: 16,
                    ),
                  );
                }).toList(),
                Container(
                  alignment: Alignment.centerRight,
                  width: 24.0 * (myRes.toString().length),
                  height: height / 3,
                  child: Text(
                    '$myRes',
                    style: _styleUtils.textStyle(30, 1),
                  ),
                  margin: EdgeInsets.only(left: 7),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  /// 状态，
  Widget _buildValveStatus({
    String title = '',
    double valve = 0.0,
    double width = 0,
    double height = 0,
    bool isCgf = true,
  }) {
    final double val = isCgf ? 2.0 : 3.0;
    int run = null == valve
        ? 5
        : 1.0 == valve
            ? 7
            : 5;
    int end = null == valve
        ? 5
        : val == valve
            ? 4
            : 5;
    return Container(
      decoration: this._styleUtils.radius(6, 10),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          // 名称
          Container(
            alignment: Alignment.center,
            width: width,
            height: height / 3,
            child: Text(
              title,
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          // 状态
          Container(
            alignment: Alignment.center,
            width: width,
            height: height / 2,
            child: Row(
              children: [
                // 运行
                Container(
                  alignment: Alignment.center,
                  width: width * 0.4,
                  height: height / 2,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 18,
                        height: 18,
                        decoration: _styleUtils.radius(run, 18),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: width * 0.4,
                        height: 24,
                        child: Text(
                          isCgf ? '打开' : '运行',
                          textAlign: TextAlign.center,
                          style: _styleUtils.textStyle(12, 1),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
                // 停止
                Container(
                  alignment: Alignment.center,
                  width: width * 0.4,
                  height: height / 2,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 18,
                        height: 18,
                        decoration: _styleUtils.radius(end, 18),
                      ),
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: width * 0.4,
                        height: 24,
                        child: Text(
                          isCgf ? '关闭' : '停止',
                          textAlign: TextAlign.center,
                          style: _styleUtils.textStyle(12, 1),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  /// 粗管阀控制
  Widget _buildValveControl({
    String title = '',
    double width = 0,
    double height = 0,
  }) {
    return Container(
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: width,
            height: 30,
            child: Text(
              title,
              style: _styleUtils.textStyle(14, 1),
            ),
            padding: EdgeInsets.only(left: 5),
          ),
          Container(
            alignment: Alignment.centerLeft,
            width: width,
            height: 50,
            child: Row(
              children: [
                Container(
                  width: width * 0.3,
                  height: 40,
                  child: _styleUtils.normal('打开', 14, () {
                    PlcTcpUtils.instance.send('000500000001', () {});
                  }),
                ),
                Container(width: 10, height: 10),
                Container(
                  width: width * 0.3,
                  height: 40,
                  child: _styleUtils.normal('关闭', 14, () {
                    PlcTcpUtils.instance.send('000500000002', () {});
                  }),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  /// 西门子流量计
  Widget _buildFlowXmz({
    String title = '',
    double width = 0,
    double height = 0,
  }) {
    List<Map<String, dynamic>> list = [];
    // 压力
    Map<String, dynamic> mapYl = Map();
    mapYl['name'] = '压力(kPa)';
    mapYl['text'] = this._flowXmz.pre;
    list.add(mapYl);
    // 温度
    Map<String, dynamic> mapWd = Map();
    mapWd['name'] = '温度(℃)';
    mapWd['text'] = this._flowXmz.tem;
    list.add(mapWd);
    // 标况瞬时
    Map<String, dynamic> mapBkss = Map();
    mapBkss['name'] = '标况瞬时流量(m³/h)';
    mapBkss['text'] = this._flowXmz.ssFlowBk;
    list.add(mapBkss);
    // 标况累积
    Map<String, dynamic> mapBklj = Map();
    mapBklj['name'] = '标况累积流量(m³)';
    mapBklj['text'] = this._flowXmz.ljFlowBk;
    list.add(mapBklj);
    // 工况瞬时
    Map<String, dynamic> mapGkss = Map();
    mapGkss['name'] = '工况瞬时流量(m³/h)';
    mapGkss['text'] = this._flowXmz.ssFlow;
    list.add(mapGkss);
    // 工况累积
    Map<String, dynamic> mapGklj = Map();
    mapGklj['name'] = '工况累积流量(m³)';
    mapGklj['text'] = this._flowXmz.ljFlow;
    list.add(mapGklj);
    return Container(
      decoration: this._styleUtils.radius(6, 10),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(top: 5, bottom: 5),
            width: width,
            height: 30,
            child: Text(
              title,
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          Container(
            alignment: Alignment.topCenter,
            width: width,
            height: height - 30,
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: list.map((e) {
                dynamic temp = e['text'];
                String text = null == temp
                    ? '0.00'
                    : ((temp as double).toStringAsFixed(2));
                return Container(
                  alignment: Alignment.center,
                  width: width / list.length,
                  height: height - 35,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: width / list.length,
                        height: (height - 40) * 0.62,
                        child: Text(
                          text,
                          style: _styleUtils.textStyle(30, 1),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topCenter,
                        width: width / list.length,
                        height: (height - 40) * 0.37,
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '${e['name']}',
                          style: _styleUtils.textStyle(12, 1),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                );
              }).toList(),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  /// 格式化数据
  Map<String, String> _fromat({
    String name,
    double value,
    double standard,
  }) {
    Map<String, String> map = Map();
    map['name'] = name ?? '';
    if (null == value) value = 0.0;
    map['text'] = value.toStringAsFixed(3);
    if (null == standard) standard = 0.0;
    map['standard'] = standard < 0 ? '' : standard.toStringAsFixed(3);
    return map;
  }

  /// 色谱仪
  Widget _buildSepuyi({
    String title = '',
    double width = 0,
    double height = 0,
  }) {
    // 常量
    List<Map<String, String>> listCL = [];
    listCL.add(this._fromat(
      name: '求和因子',
      value: this._obSpy.sumFactor,
    ));
    listCL.add(this._fromat(
      name: '分子量(kg/kmol)',
      value: this._obSpy.moWeight,
    ));
    listCL.add(this._fromat(
      name: '密度(kg/m³)',
      value: this._obSpy.density,
    ));
    listCL.add(this._fromat(
      name: '相对密度',
      value: this._obSpy.densityRel,
    ));
    List<Map<String, String>> listCs = []; // 非标准
    listCs.add(this._fromat(
      name: '氮气(mol%)',
      value: this._obSpy.n2,
      standard: this._obSpy.sn2,
    ));
    listCs.add(this._fromat(
      name: '甲烷(mol%)',
      value: this._obSpy.ch4,
      standard: this._obSpy.sch4,
    ));
    listCs.add(this._fromat(
      name: '二氧化碳(mol%)',
      value: this._obSpy.co2,
      standard: this._obSpy.sco2,
    ));
    listCs.add(this._fromat(
      name: '乙烷(mol%)',
      value: this._obSpy.c2h6,
      standard: this._obSpy.sc2h6,
    ));
    listCs.add(this._fromat(
      name: '丙烷(mol%)',
      value: this._obSpy.c3h8,
      standard: this._obSpy.sc3h8,
    ));
    listCs.add(this._fromat(
      name: '异丁烷(mol%)',
      value: this._obSpy.c4h10iso,
      standard: this._obSpy.sc4h10iso,
    ));
    listCs.add(this._fromat(
      name: '正丁烷(mol%)',
      value: this._obSpy.c4h10n,
      standard: this._obSpy.sc4h10n,
    ));
    listCs.add(this._fromat(
      name: '新戊烷(mol%)',
      value: this._obSpy.c5h12neo,
      standard: this._obSpy.sc5h12neo,
    ));
    listCs.add(this._fromat(
      name: '异戊烷(mol%)',
      value: this._obSpy.c5h12iso,
      standard: this._obSpy.sc5h12iso,
    ));
    listCs.add(this._fromat(
      name: '正戊烷(mol%)',
      value: this._obSpy.c5h12n,
      standard: this._obSpy.sc5h12n,
    ));

    listCs.add(this._fromat(
      name: '己烷及以上(mol%)',
      value: this._obSpy.c6p,
      standard: this._obSpy.sc6p,
    ));
    listCs.add(this._fromat(
      name: '总含量(mol%)',
      value: this._obSpy.nsTotal,
      standard: -1,
    ));
    // List<Map<String, String>> listBz = []; // 标准
    // listBz.add(this._fromat(
    //   name: '氮气(mol%)',
    //   value: this._obSpy.sn2,
    // ));
    // listBz.add(this._fromat(
    //   name: '甲烷(mol%)',
    //   value: this._obSpy.sch4,
    // ));
    // listBz.add(this._fromat(
    //   name: '二氧化碳(mol%)',
    //   value: this._obSpy.sco2,
    // ));
    // listBz.add(this._fromat(
    //   name: '乙烷(mol%)',
    //   value: this._obSpy.sc2h6,
    // ));
    // listBz.add(this._fromat(
    //   name: '丙烷(mol%)',
    //   value: this._obSpy.sc3h8,
    // ));
    // listBz.add(this._fromat(
    //   name: '异丁烷(mol%)',
    //   value: this._obSpy.sc4h10iso,
    // ));
    // listBz.add(this._fromat(
    //   name: '正丁烷(mol%)',
    //   value: this._obSpy.sc4h10n,
    // ));
    // listBz.add(this._fromat(
    //   name: '新戊烷(mol%)',
    //   value: this._obSpy.sc5h12neo,
    // ));
    // listBz.add(this._fromat(
    //   name: '异戊烷(mol%)',
    //   value: this._obSpy.sc5h12iso,
    // ));
    // listBz.add(this._fromat(
    //   name: '正戊烷(mol%)',
    //   value: this._obSpy.sc5h12n,
    // ));
    // listBz.add(this._fromat(
    //   name: '己烷及以上(vol%)',
    //   value: this._obSpy.sc6p,
    // ));
    List<Map<String, String>> listQt = []; // 热量值
    listQt.add(this._fromat(
      name: '高位质量发热量(MJ/kg)',
      value: this._obSpy.tHeatMass,
    ));
    listQt.add(this._fromat(
      name: '低位质量发热量(MJ/kg)',
      value: this._obSpy.nHeatMass,
    ));
    listQt.add(this._fromat(
      name: '高位体积发热量(MJ/m³)',
      value: this._obSpy.tHeatVol,
    ));
    listQt.add(this._fromat(
      name: '低位体积发热量(MJ/m³)',
      value: this._obSpy.nHeatVol,
    ));
    listQt.add(this._fromat(
      name: '高位沃泊指数(MJ/m³)',
      value: this._obSpy.wobbeTotal,
    ));
    listQt.add(this._fromat(
      name: '低位沃泊指数(MJ/m³)',
      value: this._obSpy.wobbeNet,
    ));
    double clWidth = (width - 0.1) / 4;
    double fclWidth = (width - 0.1) / 5;
    return Container(
      decoration: this._styleUtils.radius(6, 10),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 10),
            width: width,
            height: 40,
            child: Text(
              title,
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            width: width,
            height: 20,
            padding: EdgeInsets.only(left: 20),
            child: Text(
              '常量',
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          // _buildColumnNameText(width: width, height: 50),
          Container(
            alignment: Alignment.center,
            width: width,
            height: 50,
            child: Row(
              children: [
                ...listCL.map((map) {
                  return Container(
                    padding: EdgeInsets.only(left: 20),
                    alignment: Alignment.centerLeft,
                    width: clWidth,
                    height: 50,
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.bottomLeft,
                          width: clWidth,
                          height: 25,
                          child: Text(
                            map['text'],
                            style: _styleUtils.textStyle(16, 1),
                          ),
                        ),
                        Container(
                          alignment: Alignment.topLeft,
                          width: clWidth,
                          height: 25,
                          child: Text(
                            map['name'],
                            style: _styleUtils.textStyle(16, 1),
                          ),
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                    ),
                  );
                }).toList()
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            width: width,
            height: 30,
            padding: EdgeInsets.only(left: 20, bottom: 5),
            child: Text(
              '非常量',
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: width,
            height: height - 150,
            child: Row(
              children: [
                Container(
                  alignment: Alignment.center,
                  width: fclWidth * 3,
                  height: height - 150,
                  child: Column(
                    children: [
                      _buildNameTitle(
                        width: fclWidth * 3,
                        height: 22,
                      ),
                      ...listCs.map((e) {
                        return this._buildNameList(
                          width: fclWidth * 3,
                          height: 20,
                          left: 0.4,
                          right: 0.3,
                          map: e,
                          aligment: Alignment.centerRight,
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: fclWidth * 2,
                  height: height - 150,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.topCenter,
                        width: fclWidth * 2,
                        padding: EdgeInsets.only(left: 80),
                        height: 20,
                        child: Text(
                          '其他量',
                          style: _styleUtils.textStyle(16, 1),
                        ),
                      ),
                      ...listQt.map((e) {
                        return this._buildNameText(
                          width: fclWidth * 2,
                          height: 21,
                          left: 0.7,
                          right: 0.3,
                          map: e,
                          aligment: Alignment.centerRight,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Container(
          //   alignment: Alignment.center,
          //   width: width,
          //   height: height - 60 - 20,
          //   padding: EdgeInsets.only(bottom: 20),
          //   child: Row(
          //     children: [
          //       Container(
          //         alignment: Alignment.center,
          //         width: _width1,
          //         height: _height * 0.95,
          //         child: Column(
          //           children: list1.map((map) {
          //             double itemH = _height * 0.95 / 12;
          //             return Container(
          //               alignment: Alignment.center,
          //               width: _width1,
          //               height: itemH,
          //               child: Row(
          //                 children: [
          //                   Container(
          //                     alignment: Alignment.centerLeft,
          //                     width: _width1 * 0.30,
          //                     height: itemH,
          //                     child: Text(
          //                       map['name'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                   Container(
          //                     alignment: Alignment.centerRight,
          //                     width: _width1 * 0.40,
          //                     height: itemH,
          //                     child: Text(
          //                       map['text'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                 ],
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 crossAxisAlignment: CrossAxisAlignment.center,
          //               ),
          //             );
          //           }).toList(),
          //           mainAxisAlignment: MainAxisAlignment.start,
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //         ),
          //       ),
          //       Container(
          //         alignment: Alignment.center,
          //         width: _width2,
          //         height: _height * 0.95,
          //         child: Column(
          //           children: list2.map((map) {
          //             double itemH = _height * 0.95 / 12;
          //             return Container(
          //               alignment: Alignment.center,
          //               width: _width2,
          //               height: itemH,
          //               child: Row(
          //                 children: [
          //                   Container(
          //                     alignment: Alignment.centerLeft,
          //                     width: _width2 * 0.35,
          //                     height: itemH,
          //                     child: Text(
          //                       map['name'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                   Container(
          //                     alignment: Alignment.centerRight,
          //                     width: _width2 * 0.40,
          //                     height: itemH,
          //                     child: Text(
          //                       map['text'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                 ],
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 crossAxisAlignment: CrossAxisAlignment.center,
          //               ),
          //             );
          //           }).toList(),
          //           mainAxisAlignment: MainAxisAlignment.start,
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //         ),
          //       ),
          //       Container(
          //         alignment: Alignment.center,
          //         width: _width3,
          //         height: _height * 0.95,
          //         child: Column(
          //           children: list3.map((map) {
          //             double itemH = _height * 0.95 / 12;
          //             return Container(
          //               alignment: Alignment.center,
          //               width: _width3,
          //               height: itemH,
          //               child: Row(
          //                 children: [
          //                   Container(
          //                     alignment: Alignment.centerLeft,
          //                     width: _width3 * 0.45,
          //                     height: itemH,
          //                     child: Text(
          //                       map['name'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                   Container(
          //                     alignment: Alignment.centerRight,
          //                     width: _width3 * 0.40,
          //                     height: itemH,
          //                     child: Text(
          //                       map['text'],
          //                       style: _styleUtils.textStyle(16, 1),
          //                     ),
          //                   ),
          //                 ],
          //                 mainAxisAlignment: MainAxisAlignment.center,
          //                 crossAxisAlignment: CrossAxisAlignment.center,
          //               ),
          //             );
          //           }).toList(),
          //           mainAxisAlignment: MainAxisAlignment.start,
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //         ),
          //       ),
          //     ],
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //   ),
          // ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _buildNameText({
    double width,
    double height = 30,
    double left,
    double right,
    AlignmentGeometry aligment = Alignment.centerRight,
    Map<String, String> map,
  }) {
    double itemWidth = width - 40 - 0.05;
    return Container(
      // color: Colors.amber,
      padding: EdgeInsets.only(left: 20, right: 20),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: itemWidth * left,
            height: 30,
            child: Text(
              map['name'],
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            alignment: aligment,
            width: itemWidth * right,
            height: 30,
            child: Text(
              map['text'],
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _buildNameList({
    double width,
    double height = 50,
    double left,
    double right,
    AlignmentGeometry aligment = Alignment.centerLeft,
    Map<String, String> map,
  }) {
    double itemWidth = width - 40 - 0.05;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: itemWidth * left,
            height: 20,
            child: Text(
              map['name'],
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: itemWidth * right,
            height: 20,
            child: Text(
              map['text'],
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 10),
            alignment: Alignment.center,
            width: itemWidth * right,
            height: 20,
            child: Text(
              '${map['standard']}',
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  /// 西门子流量计
  Widget _buildDataGns({
    String title = '',
    double width = 0,
    double height = 0,
  }) {
    List<Map<String, dynamic>> list = [];
    // 质量发热量
    Map<String, dynamic> mapYl = Map();
    mapYl['name'] = '质量发热量(MJ/kg)';
    mapYl['text'] = this._energy.qcMassCalorific;
    list.add(mapYl);
    // 体积发热量
    Map<String, dynamic> mapWd = Map();
    mapWd['name'] = '体积发热量(MJ/m³)';
    mapWd['text'] = this._energy.qcVolumeCalorific;
    list.add(mapWd);
    // 摩尔质量
    Map<String, dynamic> mapBkss = Map();
    mapBkss['name'] = '摩尔质量(g/kmol)';
    mapBkss['text'] = this._energy.qcMolar;
    list.add(mapBkss);
    // 能量值
    Map<String, dynamic> mapBklj = Map();
    mapBklj['name'] = '能量值(MJ)';
    mapBklj['text'] = this._energy.qcEnergy;
    list.add(mapBklj);
    return Container(
      decoration: this._styleUtils.radius(6, 10),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(top: 5, bottom: 5),
            width: width,
            height: 30,
            child: Text(
              title,
              style: _styleUtils.textStyle(16, 0),
            ),
          ),
          Container(
            alignment: Alignment.topCenter,
            width: width,
            height: height - 30,
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              children: list.map((e) {
                dynamic temp = e['text'];
                String text = null == temp
                    ? '0.00'
                    : ((temp as double).toStringAsFixed(2));
                return Container(
                  alignment: Alignment.center,
                  width: width / list.length,
                  height: height - 35,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.bottomCenter,
                        width: width / list.length,
                        height: (height - 40) * 0.62,
                        child: Text(
                          text,
                          style: _styleUtils.textStyle(30, 1),
                        ),
                      ),
                      Container(
                        alignment: Alignment.topCenter,
                        width: width / list.length,
                        height: (height - 40) * 0.37,
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          '${e['name']}',
                          style: _styleUtils.textStyle(12, 1),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                );
              }).toList(),
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _buildNameTitle({
    double width,
    double height = 50,
  }) {
    double itemWidth = width - 40 - 0.05;
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      alignment: Alignment.center,
      width: width,
      height: height,
      child: Row(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            width: itemWidth * 0.4,
            height: 30,
            child: Text(
              '被测天然气组分',
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: itemWidth * 0.3,
            height: 30,
            child: Text(
              '未归一化含量',
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: itemWidth * 0.3,
            height: 30,
            child: Text(
              '归一化含量',
              style: _styleUtils.textStyle(16, 1),
            ),
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}
