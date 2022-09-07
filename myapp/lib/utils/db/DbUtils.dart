import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:myapp/utils/bean/Bean.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 数据库工具类
/// Created in 2021-08-25 09:43:44 by YinRH
class DbUtils {
  factory DbUtils() => _getInstance();
  static DbUtils get instance => _getInstance();
  static DbUtils _instance;

  DbUtils._internal() {
    // 初始化数据
  }

  static DbUtils _getInstance() {
    if (null == _instance) {
      _instance = new DbUtils._internal();
    }
    return _instance;
  }

  static final String tabGnsTcp = 'GnsTcp'; // 表格：传感网络
  static final String tabFan = 'Fan'; // 表格：风机状态
  static final String tabCrudeSTA = 'CrudeSTA'; // 表格：粗管阀状态
  static final String tabFineSTA = 'FineSTA'; // 表格：细管阀状态
  static final String tabFlowWdyb = 'FlowWdyb'; // 表格：流量计-维度仪表
  static final String tabFlowXmz = 'FlowXmz'; // 表格：流量计-西门子
  static final String tabFineTEM = 'FineTEM'; // 表格：细管阀温度
  static final String tabFinePRE = 'FinePRE'; // 表格：细管阀压力
  static final String tabSpy = 'Spy'; // 表格：色谱仪
  static final String tabAlarmGas = 'AlarmGas'; // 表格：可燃气体报警器
  static final String tabAlarm = 'Alarm'; // 表格：报警器

  Database mDb; // 数据库 Database 对象
  LinkedList<DbBean> mList = LinkedList();

  /// 初始化数据库
  Future<void> init() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String dbPath = directory.path + '/myapp_nljl.db';
    print('database path: ' + dbPath);
    mDb = await databaseFactoryFfi.openDatabase(dbPath);
    await mDb.transaction((transaction) async {
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabGnsTcp' " +
          "(id INTEGER PRIMARY KEY,ip TEXT,port TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabFan' " +
          "(id INTEGER PRIMARY KEY,tempFront TEXT,tempAfter TEXT," +
          "shockFront TEXT,shockAfter TEXT,output TEXT,runSpeed TEXT," +
          "runRate TEXT,setRate TEXT,inVal TEXT,inValFeed TEXT," +
          "runShow TEXT,alarm TEXT,ventOpen TEXT,ventClose TEXT," +
          "alarmRest TEXT,local TEXT,control TEXT,site TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabCrudeSTA' " +
          "(id INTEGER PRIMARY KEY,crudeVal TEXT,site TEXT,loop TEXT," +
          "time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabFineSTA' " +
          "(id INTEGER PRIMARY KEY,fineVal TEXT,site TEXT,loop TEXT," +
          "time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabFlowWdyb' " +
          "(id INTEGER PRIMARY KEY,totalSC01 TEXT,totalSC02 TEXT," +
          "streamSC TEXT,streamWC TEXT,realPre TEXT,realTem TEXT," +
          "totalWC01 TEXT,totalWC02 TEXT,battery TEXT,site TEXT," +
          "loop TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabFineTEM' " +
          "(id INTEGER PRIMARY KEY,fineTem TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabFinePRE' " +
          "(id INTEGER PRIMARY KEY,finePre TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabSpy' " +
          "(id INTEGER PRIMARY KEY,n2 TEXT,ch4 TEXT,co2 TEXT," +
          "c2h6 TEXT,c3h8 TEXT,c4h10iso TEXT,c4h10n TEXT," +
          "c5h12neo TEXT,c5h12iso TEXT,c5h12n TEXT,c6p TEXT," +
          "nsTotal TEXT,sn2 TEXT,sch4 TEXT,sco2 TEXT,sc2h6 TEXT," +
          "sc3h8 TEXT,sc4h10iso TEXT,sc4h10n TEXT,sc5h12neo TEXT," +
          "sc5h12iso TEXT,sc5h12n TEXT,sc6p TEXT,tHeatMass TEXT," +
          "nHeatMass TEXT,tHeatVol TEXT,nHeatVol TEXT," +
          "sumFactor TEXT,moWeight TEXT,density TEXT,densityRel TEXT," +
          "wobbeTotal TEXT,wobbeNet TEXT,spare TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabAlarmGas' " +
          "(id INTEGER PRIMARY KEY,alarmGas TEXT,site TEXT,time TEXT)");
      await transaction.execute("CREATE TABLE IF NOT EXISTS '$tabAlarm' " +
          "(id INTEGER PRIMARY KEY,alarm TEXT,site TEXT,time TEXT)");
    });
  }

  /// 轮循处理 DB 读写任务
  Future<void> timer() async {
    if (null != mList && 0 != mList.length) {
      DbBean dbBean = this.mList.first;
      this.mList.remove(dbBean);
      switch (dbBean.type) {
        case 0: // 读GNS
          await this._readGns().then((gnsBean) {
            dbBean.cb(gnsBean);
            this.timer();
          });
          break;
        case 1: // 写GNS
          GnsBean gnsBean = dbBean.ob as GnsBean;
          this._saveGns(gnsBean.ip, gnsBean.port);
          this.timer();
          break;
        case 2: // 读PLC
          await this._readPlc().then((gnsData) {
            dbBean.cb(gnsData);
            this.timer();
          });
          break;
        case 3: // 写PLC
          this._savePlc(dbBean.ob as PlcData);
          this.timer();
          break;
      }
    } else {
      Timer(Duration(seconds: 1), () => timer());
    }
  }

  /// 添加 DB 读写任务
  void add(DbBean dbBean) async {
    // if (150 < mList.length) {
    //   this.mList.clear();
    // }
    this.mList.add(dbBean);
  }

  /// 保存 GNS 传感网络 IP 和 PORT
  Future<void> _saveGns(String ip, String port) async {
    await mDb.transaction((transaction) async {
      await transaction.rawDelete("DELETE FROM '$tabGnsTcp'"); // 删除
      await transaction.rawInsert(
          "INSERT INTO $tabGnsTcp (ip,port) VALUES ('$ip', '$port')");
    });
  }

  /// 读取 GNS 传感网络 IP 和 PORT
  Future<GnsBean> _readGns() async {
    List list = await mDb.query(tabGnsTcp);
    GnsBean gnsBean = GnsBean();
    if (null != list && 0 != list.length) {
      gnsBean.ip = list[0]['ip'];
      gnsBean.port = list[0]['port'];
    }
    return gnsBean;
  }

  /// 保存 PLC 传递的数据
  Future<void> _savePlc(PlcData plcData) async {
    String time = new DateTime.now().toString();
    time = time.substring(0, 19);
    // print('save data to db by ' + time);
    switch (plcData.type) {
      // case 1: // 风机
      //   ObFan obFan = plcData.ob as ObFan;
      //   obFan.site = '秦川';
      //   await mDb.rawInsert("" +
      //       "INSERT INTO $tabFan (tempFront,tempAfter,shockFront," +
      //       "shockAfter,output,runSpeed,runRate,setRate,inVal," +
      //       "inValFeed,runShow,alarm,ventOpen,ventClose,alarmRest," +
      //       "local,control,site,time) VALUES ('${obFan.tempFront}'," +
      //       "'${obFan.tempAfter}','${obFan.shockFront}'," +
      //       "'${obFan.shockAfter}','${obFan.output}'," +
      //       "'${obFan.runSpeed}','${obFan.runRate}','${obFan.setRate}'," +
      //       "'${obFan.inVal}','${obFan.inValFeed}','${obFan.runShow}'," +
      //       "'${obFan.alarm}','${obFan.ventOpen}','${obFan.ventClose}'," +
      //       "'${obFan.alarmRest}','${obFan.local}','${obFan.control}'," +
      //       "'${obFan.site}','$time')");
      //   break;
      case 2: // DN100回路阀门状态
        ObCrudeSTA obCrudeSTA = plcData.ob as ObCrudeSTA;
        obCrudeSTA.site = '秦川';
        obCrudeSTA.loop = '回路-粗管阀';
        await mDb.rawInsert("" +
            "INSERT INTO $tabCrudeSTA (crudeVal,site,loop,time) " +
            "VALUES ('${obCrudeSTA.crudeVal}'," +
            "'${obCrudeSTA.site}','${obCrudeSTA.loop}','$time')");
        break;
      case 3: // 防爆风机
        ObFineSTA obFineSTA = plcData.ob as ObFineSTA;
        obFineSTA.site = '秦川';
        obFineSTA.loop = '回路-细管阀';
        await mDb.rawInsert("" +
            "INSERT INTO $tabFineSTA (fineVal,site,loop,time) " +
            "VALUES ('${obFineSTA.fineVal}'," +
            "'${obFineSTA.site}','${obFineSTA.loop}','$time')");
        break;
      // case 4: // 流量计-维度仪表
      //   ObFlowWdyb obFlowWdyb = plcData.ob as ObFlowWdyb;
      //   obFlowWdyb.site = '秦川';
      //   obFlowWdyb.loop = '回路-维度仪表';
      //   await mDb.rawInsert("" +
      //       "INSERT INTO $tabFlowWdyb (totalSC01,totalSC02,streamSC," +
      //       "streamWC,realPre,realTem,totalWC01,totalWC02,battery," +
      //       "site,loop,time) VALUES ('${obFlowWdyb.totalSC01}'," +
      //       "'${obFlowWdyb.totalSC02}','${obFlowWdyb.streamSC}'," +
      //       "'${obFlowWdyb.streamWC}','${obFlowWdyb.realPre}'," +
      //       "'${obFlowWdyb.realTem}','${obFlowWdyb.totalWC01}'," +
      //       "'${obFlowWdyb.totalWC02}','${obFlowWdyb.battery}'," +
      //       "'${obFlowWdyb.site}','${obFlowWdyb.loop}','$time')");
      //   break;
      case 5: // 西客流量计
        break;
      // case 6: // 细管阀温度
      //   ObFineTEM obFineTEM = plcData.ob as ObFineTEM;
      //   await mDb.rawInsert("" +
      //       "INSERT INTO $tabFineTEM (fineTem,time) " +
      //       "VALUES ('${obFineTEM.fineTem}','$time')");
      //   break;
      // case 7: // 细管阀压力
      //   ObFinePRE obFinePRE = plcData.ob as ObFinePRE;
      //   await mDb.rawInsert("" +
      //       "INSERT INTO $tabFinePRE (finePre,time) " +
      //       "VALUES ('${obFinePRE.finePre}','$time')");
      //   break;
      case 8: // 色谱仪
        ObSpy obSpy = plcData.ob as ObSpy;
        // 屏蔽预热阶段的数据
        if (null == obSpy.n2 || 65535.0 == obSpy.n2) break;
        await mDb.rawInsert("" +
            "INSERT INTO $tabSpy (n2,ch4,co2,c2h6,c3h8,c4h10iso," +
            "c4h10n,c5h12neo,c5h12iso,c5h12n,c6p,nsTotal,sn2,sch4," +
            "sco2,sc2h6,sc3h8,sc4h10iso,sc4h10n,sc5h12neo,sc5h12iso," +
            "sc5h12n,sc6p,tHeatMass,nHeatMass,tHeatVol,nHeatVol," +
            "sumFactor,moWeight,density,densityRel,wobbeTotal,wobbeNet," +
            "spare,time) VALUES ('${obSpy.n2}','${obSpy.ch4}'," +
            "'${obSpy.co2}','${obSpy.c2h6}','${obSpy.c3h8}'," +
            "'${obSpy.c4h10iso}','${obSpy.c4h10n}','${obSpy.c5h12neo}'," +
            "'${obSpy.c5h12iso}','${obSpy.c5h12n}','${obSpy.c6p}'," +
            "'${obSpy.nsTotal}','${obSpy.sn2}','${obSpy.sch4}'," +
            "'${obSpy.sco2}','${obSpy.sc2h6}','${obSpy.sc3h8}'," +
            "'${obSpy.sc4h10iso}','${obSpy.sc4h10n}'," +
            "'${obSpy.sc5h12neo}','${obSpy.sc5h12iso}'," +
            "'${obSpy.sc5h12n}','${obSpy.sc6p}','${obSpy.tHeatMass}'," +
            "'${obSpy.nHeatMass}','${obSpy.tHeatVol}'," +
            "'${obSpy.nHeatVol}','${obSpy.sumFactor}'," +
            "'${obSpy.moWeight}','${obSpy.density}'," +
            "'${obSpy.densityRel}','${obSpy.wobbeTotal}'," +
            "'${obSpy.wobbeNet}','${obSpy.spare}','$time')");
        break;
      case 9: // 可燃气体报警器
        ObAlarmGas obAlarmGas = plcData.ob as ObAlarmGas;
        obAlarmGas.site = '秦川';
        await mDb.rawInsert("" +
            "INSERT INTO $tabAlarmGas (alarmGas,site,time) VALUES " +
            "('${obAlarmGas.alarmGas}','${obAlarmGas.site}','$time')");
        break;
      // case 10: // 报警器
      //   ObAlarm obAlarm = plcData.ob as ObAlarm;
      //   obAlarm.site = '秦川';
      //   await mDb.rawInsert("" +
      //       "INSERT INTO $tabAlarm (alarm,site,time) VALUES " +
      //       "('${obAlarm.alarm}','${obAlarm.site}','$time')");
      //   break;
    }
  }

  /// 判断数组是否为 null 或 0-length
  bool _isEmpty(List list) {
    return null == list || 0 == list.length;
  }

  /// 读取 GNS 传感网络 IP 和 PORT
  Future<GnsData> _readPlc() async {
    GnsData gnsData = GnsData();
    await mDb.transaction((transaction) async {
      List list = [];
      // 风机状态
      // list = await transaction.query(
      //   tabFan,
      //   orderBy: 'time DESC',
      //   limit: 1,
      // );
      // if (!isEmpty(list)) {
      //   Map<String, Object> map = list[0];
      //   ObFan obFan = ObFan();
      //   obFan.tempFront = double.parse(map['tempFront']);
      //   obFan.tempAfter = double.parse(map['tempAfter']);
      //   obFan.shockFront = double.parse(map['shockFront']);
      //   obFan.shockAfter = double.parse(map['shockAfter']);
      //   obFan.output = double.parse(map['output']);
      //   obFan.runSpeed = double.parse(map['runSpeed']);
      //   obFan.runRate = double.parse(map['runRate']);
      //   obFan.setRate = double.parse(map['setRate']);
      //   obFan.inVal = double.parse(map['inVal']);
      //   obFan.inValFeed = double.parse(map['inValFeed']);
      //   obFan.runShow = double.parse(map['runShow']);
      //   obFan.alarm = double.parse(map['alarm']);
      //   obFan.ventOpen = double.parse(map['ventOpen']);
      //   obFan.ventClose = double.parse(map['ventClose']);
      //   obFan.alarmRest = double.parse(map['alarmRest']);
      //   obFan.local = double.parse(map['local']);
      //   obFan.control = double.parse(map['control']);
      //   obFan.site = map['site'];
      //   obFan.time = map['time'];
      //   gnsData.obFan = obFan;
      // }
      // DN100回路阀门状态
      list = await transaction.query(
        tabCrudeSTA,
        orderBy: 'time DESC',
        limit: 1,
      );
      if (!_isEmpty(list)) {
        Map<String, Object> map = list[0];
        ObCrudeSTA obCrudeSTA = ObCrudeSTA();
        obCrudeSTA.crudeVal = double.parse(map['crudeVal']);
        obCrudeSTA.site = map['site'];
        obCrudeSTA.loop = map['loop'];
        obCrudeSTA.time = map['time'];
        gnsData.obCrudeSTA = obCrudeSTA;
      }
      // 防爆风机
      list = await transaction.query(
        tabFineSTA,
        orderBy: 'time DESC',
        limit: 1,
      );
      if (!_isEmpty(list)) {
        Map<String, Object> map = list[0];
        ObFineSTA obFineSTA = ObFineSTA();
        obFineSTA.fineVal = double.parse(map['fineVal']);
        obFineSTA.site = map['site'];
        obFineSTA.loop = map['loop'];
        obFineSTA.time = map['time'];
        gnsData.obFineSTA = obFineSTA;
      }
      // 流量计-维度仪表
      // list = await transaction.query(
      //   tabFlowWdyb,
      //   orderBy: 'time DESC',
      //   limit: 1,
      // );
      // if (!isEmpty(list)) {
      //   Map<String, Object> map = list[0];
      //   ObFlowWdyb obFlowWdyb = ObFlowWdyb();
      //   obFlowWdyb.totalSC01 = double.parse(map['totalSC01']);
      //   obFlowWdyb.totalSC02 = double.parse(map['totalSC02']);
      //   obFlowWdyb.streamSC = double.parse(map['streamSC']);
      //   obFlowWdyb.streamWC = double.parse(map['streamWC']);
      //   obFlowWdyb.realPre = double.parse(map['realPre']);
      //   obFlowWdyb.realTem = double.parse(map['realTem']);
      //   obFlowWdyb.totalWC01 = double.parse(map['totalWC01']);
      //   obFlowWdyb.totalWC02 = double.parse(map['totalWC02']);
      //   obFlowWdyb.battery = double.parse(map['battery']);
      //   obFlowWdyb.site = map['site'];
      //   obFlowWdyb.loop = map['loop'];
      //   obFlowWdyb.time = map['time'];
      //   gnsData.obFlowWdyb = obFlowWdyb;
      // }
      // 西客流量计
      // ObFlowXmz obFlowXmz = ObFlowXmz();
      // gnsData.obFlowXmz = obFlowXmz;
      // 细管阀温度
      // list = await transaction.query(
      //   tabFineTEM,
      //   orderBy: 'time DESC',
      //   limit: 1,
      // );
      // if (!isEmpty(list)) {
      //   Map<String, Object> map = list[0];
      //   ObFineTEM obFineTEM = ObFineTEM();
      //   obFineTEM.fineTem = double.parse(map['fineTem']);
      //   obFineTEM.time = map['time'];
      //   gnsData.obFineTEM = obFineTEM;
      // }
      // // 细管阀压力
      // list = await transaction.query(
      //   tabFinePRE,
      //   orderBy: 'time DESC',
      //   limit: 1,
      // );
      // if (!isEmpty(list)) {
      //   Map<String, Object> map = list[0];
      //   ObFinePRE obFinePRE = ObFinePRE();
      //   obFinePRE.finePre = double.parse(map['finePre']);
      //   obFinePRE.time = map['time'];
      //   gnsData.obFinePRE = obFinePRE;
      // }
      // 色谱仪
      list = await transaction.query(
        tabSpy,
        orderBy: 'time DESC',
        limit: 1,
      );
      if (!_isEmpty(list)) {
        Map<String, Object> map = list[0];
        ObSpy obSpy = ObSpy();
        obSpy.n2 = double.parse(map['n2']);
        obSpy.ch4 = double.parse(map['ch4']);
        obSpy.co2 = double.parse(map['co2']);
        obSpy.c2h6 = double.parse(map['c2h6']);
        obSpy.c3h8 = double.parse(map['c3h8']);
        obSpy.c4h10iso = double.parse(map['c4h10iso']);
        obSpy.c4h10n = double.parse(map['c4h10n']);
        obSpy.c5h12neo = double.parse(map['c5h12neo']);
        obSpy.c5h12iso = double.parse(map['c5h12iso']);
        obSpy.c5h12n = double.parse(map['c5h12n']);
        obSpy.c6p = double.parse(map['c6p']);
        obSpy.nsTotal = double.parse(map['nsTotal']);
        obSpy.sn2 = double.parse(map['sn2']);
        obSpy.sch4 = double.parse(map['sch4']);
        obSpy.sco2 = double.parse(map['sco2']);
        obSpy.sc2h6 = double.parse(map['sc2h6']);
        obSpy.sc3h8 = double.parse(map['sc3h8']);
        obSpy.sc4h10iso = double.parse(map['sc4h10iso']);
        obSpy.sc4h10n = double.parse(map['sc4h10n']);
        obSpy.sc5h12neo = double.parse(map['sc5h12neo']);
        obSpy.sc5h12iso = double.parse(map['sc5h12iso']);
        obSpy.sc5h12n = double.parse(map['sc5h12n']);
        obSpy.sc6p = double.parse(map['sc6p']);
        obSpy.tHeatMass = double.parse(map['tHeatMass']);
        obSpy.nHeatMass = double.parse(map['nHeatMass']);
        obSpy.tHeatVol = double.parse(map['tHeatVol']);
        obSpy.nHeatVol = double.parse(map['nHeatVol']);
        obSpy.sumFactor = double.parse(map['sumFactor']);
        obSpy.moWeight = double.parse(map['moWeight']);
        obSpy.density = double.parse(map['density']);
        obSpy.densityRel = double.parse(map['densityRel']);
        obSpy.wobbeTotal = double.parse(map['wobbeTotal']);
        obSpy.wobbeNet = double.parse(map['wobbeNet']);
        obSpy.spare = double.parse(map['spare']);
        obSpy.time = map['time'];
        gnsData.obSpy = obSpy;
      }
      // 可燃气体报警器
      list = await transaction.query(
        tabAlarmGas,
        orderBy: 'time DESC',
        limit: 1,
      );
      if (!_isEmpty(list)) {
        Map<String, Object> map = list[0];
        ObAlarmGas obAlarmGas = ObAlarmGas();
        obAlarmGas.alarmGas = double.parse(map['alarmGas']);
        obAlarmGas.site = map['site'];
        obAlarmGas.time = map['time'];
        gnsData.obAlarmGas = obAlarmGas;
      }
      // 报警器
      // list = await transaction.query(
      //   tabAlarm,
      //   orderBy: 'time DESC',
      //   limit: 1,
      // );
      // if (!isEmpty(list)) {
      //   Map<String, Object> map = list[0];
      //   ObAlarm obAlarm = ObAlarm();
      //   obAlarm.alarm = double.parse(map['alarm']);
      //   obAlarm.site = map['site'];
      //   obAlarm.time = map['time'];
      //   gnsData.obAlarm = obAlarm;
      // }
    });
    return gnsData;
  }
}
