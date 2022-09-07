import 'dart:collection';

/// 数据
/// Created in 2021-08-25 09:43:44 by YinRH

/// PLC 网关信息实例
class PlcBean {
  String name = ''; // 名称
  String ip = ''; // IP
  int port = 8888; // 端口
}

/// GNS 传感网络实例
class GnsBean {
  String ip = ''; // IP
  String port = ''; // 端口
}

/// DB 操作数据的结构
/// [type] 0-读GNS，1-写GNS，2-读PLC，3-写PLC
class DbBean extends LinkedListEntry<DbBean> {
  DbBean({this.type, this.ob, this.cb});
  int type;
  Object ob;
  Function cb;
}

/// Gns 返回的数据结构
class ResBean {
  int code;
  String msg;
  ResData data;

  ResBean.fromJson(Map<String, dynamic> map) {
    code = map['code'];
    msg = map['msg'];
    if (map['data'] is Map<String, dynamic>) {
      Map<String, dynamic> t = map['data'];
      data = null == t ? null : ResData.fromJson(t);
    }
  }
}

/// Gns 返回的数据中data对象
class ResData {
  // 0-正常消息 1-指令
  int type;
  String text; // 指令
  ResEnergy energy;

  ResData.fromJson(Map<String, dynamic> map) {
    type = map['type'];
    text = map['text'];
    Map<String, dynamic> t = map['energy'];
    energy = ResEnergy.fromJson(t ?? {});
  }
}

/// Gns
class ResEnergy {
  double qcEnergy; // 能量
  double qcVolumeCalorific; // 体积发热量
  double qcMolar; // 摩尔质量
  double qcMassCalorific; // 质量发热量
  int qcInterval; // 间隔秒

  ResEnergy.fromJson(Map<String, dynamic> map) {
    try {
      qcEnergy = map['qcEnergy'] * 1.0;
      qcVolumeCalorific = map['qcVolumeCalorific'] * 1.0;
      qcMolar = map['qcMolar'] * 1.0;
      qcMassCalorific = map['qcMassCalorific'] * 1.0;
      qcInterval = map['qcInterval'];
    } catch (error) {
      qcEnergy = 0.00;
      qcVolumeCalorific = 0.00;
      qcMolar = 0.00;
      qcMassCalorific = 0.00;
      qcInterval = 2;
    }
  }
}

/// PLC 数据结构
/// [type] 类别：1-风机状态，2-DN100回路阀门状态，3-防爆风机，4-维度仪表流量计，
///             5-西客流量计，6-细管温度，7-细管压力，8-西门子色谱仪，
///             9-可燃气体报警器，10-报警器，11-粗管温度，12-粗管压力
class PlcData {
  int type;
  Object ob;
}

/// PLC 更新 UI
// class Wdyl {
//   int type; // 67-细管阀，1112-粗管阀
//   PlcData tem; // 温度
//   PlcData pre; // 压力
// }

/// GNS 数据结构
class GnsData {
  // ObFan obFan; // 1-风机状态
  ObCrudeSTA obCrudeSTA; // 2-DN100回路阀门状态
  ObFineSTA obFineSTA; // 3-防爆风机
  // ObFlowWdyb obFlowWdyb; // 4-维度仪表流量计
  ObFlowXmz obFlowXmz; // 5-西客流量计
  // ObFineTEM obFineTEM; // 6-细管阀温度
  // ObFinePRE obFinePRE; // 7-细管阀压力
  ObSpy obSpy; // 8- 西门子色谱仪
  ObAlarmGas obAlarmGas; // 9-可燃气体报警器
  // ObAlarm obAlarm; // 10-报警器
  // ObCrudeTEM obCrudeTEM; // 11-粗管阀温度
  // ObCrudePRE obCrudePRE; // 12-粗管阀压力
  ObEnergy obEnergy; // 13-天然气能量

  Map toJson() {
    Map map = new Map();
    // map['1'] = null == obFan ? {} : obFan;
    map['2'] = null == obCrudeSTA ? {} : obCrudeSTA;
    map['3'] = null == obFineSTA ? {} : obFineSTA;
    // map['4'] = null == obFlowWdyb ? {} : obFlowWdyb;
    map['5'] = null == obFlowXmz ? {} : obFlowXmz;
    // map['6'] = null == obFineTEM ? {} : obFineTEM;
    // map['7'] = null == obFinePRE ? {} : obFinePRE;
    map['8'] = null == obSpy ? {} : obSpy;
    map['9'] = null == obAlarmGas ? {} : obAlarmGas;
    // map['10'] = null == obAlarm ? {} : obAlarm;
    // map['11'] = null == obCrudeTEM ? {} : obCrudeTEM;
    // map['12'] = null == obCrudePRE ? {} : obCrudePRE;
    // map['13'] = null == obEnergy ? {} : obEnergy;
    return map;
  }
}

/// 1-风机状态
// class ObFan {
//   double tempFront; // 前轴承温度
//   double tempAfter; // 后轴承温度
//   double shockFront; // 前轴承震动
//   double shockAfter; // 后轴承震动
//   double output; // 输出电流
//   double runSpeed; // 运行转速
//   double runRate; // 运行频率
//   double setRate; // 设定频率
//   double inVal; // 进口阀调节
//   double inValFeed; // 进口阀反馈值
//   double runShow; // 运行显示
//   double alarm; // 凤鸣报警
//   double ventOpen; // 放空阀开
//   double ventClose; // 放空阀关
//   double alarmRest; // 报警复位
//   double local; // 0-本地，1-远程
//   double control; // 控制命令
//   String site; // 站点
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['tempFront'] = null == tempFront ? 0 : tempFront;
//     map['tempAfter'] = null == tempAfter ? 0 : tempAfter;
//     map['shockFront'] = null == shockFront ? 0 : shockFront;
//     map['shockAfter'] = null == shockAfter ? 0 : shockAfter;
//     map['output'] = null == output ? 0 : output;
//     map['runSpeed'] = null == runSpeed ? 0 : runSpeed;
//     map['runRate'] = null == runRate ? 0 : runRate;
//     map['setRate'] = null == setRate ? 0 : setRate;
//     map['inVal'] = null == inVal ? 0 : inVal;
//     map['inValFeed'] = null == inValFeed ? 0 : inValFeed;
//     map['runShow'] = null == runShow ? 0 : runShow;
//     map['alarm'] = null == alarm ? 0 : alarm;
//     map['ventOpen'] = null == ventOpen ? 0 : ventOpen;
//     map['ventClose'] = null == ventClose ? 0 : ventClose;
//     map['alarmRest'] = null == alarmRest ? 0 : alarmRest;
//     map['local'] = null == local ? 0 : local;
//     map['control'] = null == control ? 0 : control;
//     map['time'] = null == time ? '' : time;
//     map['site'] = null == site ? '' : site;
//     return map;
//   }
// }

/// 2-DN100回路阀门状态
class ObCrudeSTA {
  double crudeVal; // 粗管阀状态，1-开到位，2-关到位 3-既没开到位，又没关到位
  String site; // 站点
  String loop; // 回路
  String time; // 更新时间

  Map toJson() {
    Map map = new Map();
    map['crudeVal'] = null == crudeVal ? 0 : crudeVal;
    map['time'] = null == time ? '' : time;
    map['site'] = null == site ? '' : site;
    map['loop'] = null == loop ? '' : loop;
    return map;
  }
}

/// 3-防爆风机
class ObFineSTA {
  double fineVal; // 1-开到位，2-关到位
  String site; // 站点
  String loop; // 回路
  String time; // 更新时间

  Map toJson() {
    Map map = new Map();
    map['fineVal'] = null == fineVal ? 0 : fineVal;
    map['time'] = null == time ? '' : time;
    map['site'] = null == site ? '' : site;
    map['loop'] = null == loop ? '' : loop;
    return map;
  }
}

// /// 4-维度仪表流量计
// class ObFlowWdyb {
//   double totalSC01; // 标况总量01
//   double totalSC02; // 标况总量02
//   double streamSC; // 标况流量
//   double streamWC; // 工况流量
//   double realPre; // 实时压力
//   double realTem; // 实时温度
//   double totalWC01; // 工况总量01
//   double totalWC02; // 工况总量02
//   double battery; // 电池电压
//   String site; // 站点
//   String loop; // 回路
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['totalSC01'] = null == totalSC01 ? 0 : totalSC01;
//     // map['totalSC02'] = null == totalSC02 ? 0 : totalSC02;
//     map['streamSC'] = null == streamSC ? 0 : streamSC;
//     map['streamWC'] = null == streamWC ? 0 : streamWC;
//     map['realPre'] = null == realPre ? 0 : realPre;
//     map['realTem'] = null == realTem ? 0 : realTem;
//     map['totalWC01'] = null == totalWC01 ? 0 : totalWC01;
//     // map['totalWC02'] = null == totalWC02 ? 0 : totalWC02;
//     map['battery'] = null == battery ? 0 : battery;
//     map['time'] = null == time ? '' : time;
//     map['site'] = null == site ? '' : site;
//     map['loop'] = null == loop ? '' : loop;
//     return map;
//   }
// }

/// 5-西客流量计
class ObFlowXmz {
  double ssFlow; // 瞬时流量
  double ljFlow; // 累积流量
  double tem; // 温度
  double pre; // 压力
  double ssFlowBk; // 标况瞬时流量
  double ljFlowBk; // 标况累积流量
  String site; // 站点
  String loop; // 回路
  String time; // 更新时间

  Map toJson() {
    Map map = new Map();
    map['ssFlow'] = null == ssFlow ? 0 : ssFlow;
    map['ljFlow'] = null == ljFlow ? 0 : ljFlow;
    map['tem'] = null == tem ? 0 : tem;
    map['pre'] = null == pre ? 0 : pre;
    map['ssFlowBk'] = null == ssFlowBk ? 0 : ssFlowBk;
    map['ljFlowBk'] = null == ljFlowBk ? 0 : ljFlowBk;
    map['time'] = null == time ? '' : time;
    map['site'] = null == site ? '' : site;
    map['loop'] = null == loop ? '' : loop;
    return map;
  }
}

/// 6-细管阀温度
// class ObFineTEM {
//   double fineTem; // 细管温度
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['fineTem'] = null == fineTem ? 0 : fineTem;
//     map['time'] = null == time ? '' : time;
//     return map;
//   }
// }

/// 7-细管阀压力
// class ObFinePRE {
//   double finePre; // 细管压力
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['finePre'] = null == finePre ? 0 : finePre;
//     map['time'] = null == time ? '' : time;
//     return map;
//   }
// }

/// 8- 西门子色谱仪
class ObSpy {
  double n2; // 氮气
  double ch4; // 甲烷
  double co2; // 二氧化碳
  double c2h6; // 乙烷
  double c3h8; // 丙烷
  double c4h10iso; // 异丁烷
  double c4h10n; // 正丁烷
  double c5h12neo; // 新戊烷
  double c5h12iso; // 异戊烷
  double c5h12n; // 正戊烷
  double c6p; // c6+
  double nsTotal; // 非标总数
  double sn2; // 标准氮气
  double sch4; // 标准甲烷
  double sco2; // 标准二氧化氮
  double sc2h6; // 标准乙烷
  double sc3h8; // 标准丙烷
  double sc4h10iso; // 标准异丁烷
  double sc4h10n; // 标准正丁烷
  double sc5h12neo; // 标准新戊烷
  double sc5h12iso; // 标准异戊烷
  double sc5h12n; // 标准正戊烷
  double sc6p; // 标准c6+
  double tHeatMass; // 总热量，质量浓度
  double nHeatMass; // 净热量，质量浓度
  double tHeatVol; // 总热量，体积浓度
  double nHeatVol; // 净热量，体积浓度
  double sumFactor; // 求和因子
  double moWeight; // 分子量
  double density; // 密度
  double densityRel; // 相对密度
  double wobbeTotal; // 总的沃博值
  double wobbeNet; // 净的沃博值
  double spare; // 备用
  String time; // 更新时间

  Map toJson() {
    Map map = new Map();
    map['n2'] = null == n2 ? 0 : n2;
    map['ch4'] = null == ch4 ? 0 : ch4;
    map['co2'] = null == co2 ? 0 : co2;
    map['c2h6'] = null == c2h6 ? 0 : c2h6;
    map['c3h8'] = null == c3h8 ? 0 : c3h8;
    map['c4h10iso'] = null == c4h10iso ? 0 : c4h10iso;
    map['c4h10n'] = null == c4h10n ? 0 : c4h10n;
    map['c5h12neo'] = null == c5h12neo ? 0 : c5h12neo;
    map['c5h12iso'] = null == c5h12iso ? 0 : c5h12iso;
    map['c5h12n'] = null == c5h12n ? 0 : c5h12n;
    map['c6p'] = null == c6p ? 0 : c6p;
    map['nsTotal'] = null == nsTotal ? 0 : nsTotal;
    map['sn2'] = null == sn2 ? 0 : sn2;
    map['sch4'] = null == sch4 ? 0 : sch4;
    map['sco2'] = null == sco2 ? 0 : sco2;
    map['sc2h6'] = null == sc2h6 ? 0 : sc2h6;
    map['sc3h8'] = null == sc3h8 ? 0 : sc3h8;
    map['sc4h10iso'] = null == sc4h10iso ? 0 : sc4h10iso;
    map['sc4h10n'] = null == sc4h10n ? 0 : sc4h10n;
    map['sc5h12neo'] = null == sc5h12neo ? 0 : sc5h12neo;
    map['sc5h12iso'] = null == sc5h12iso ? 0 : sc5h12iso;
    map['sc5h12n'] = null == sc5h12n ? 0 : sc5h12n;
    map['sc6p'] = null == sc6p ? 0 : sc6p;
    map['tHeatMass'] = null == tHeatMass ? 0 : tHeatMass;
    map['nHeatMass'] = null == nHeatMass ? 0 : nHeatMass;
    map['tHeatVol'] = null == tHeatVol ? 0 : tHeatVol;
    map['nHeatVol'] = null == nHeatVol ? 0 : nHeatVol;
    map['sumFactor'] = null == sumFactor ? 0 : sumFactor;
    map['moWeight'] = null == moWeight ? 0 : moWeight;
    map['density'] = null == density ? 0 : density;
    map['densityRel'] = null == densityRel ? 0 : densityRel;
    map['wobbeTotal'] = null == wobbeTotal ? 0 : wobbeTotal;
    map['wobbeNet'] = null == wobbeNet ? 0 : wobbeNet;
    map['spare'] = null == spare ? 0 : spare;
    map['time'] = null == time ? '' : time;
    return map;
  }
}

/// 9-可燃气体报警器
class ObAlarmGas {
  double alarmGas; // 可燃气体报警
  double h2Gas; // 氢气气体报警
  double ch4Gas; // 甲烷气体报警
  String site; // 站点
  String time; // 更新时间

  Map toJson() {
    Map map = new Map();
    map['alarmGas'] = null == alarmGas ? 0 : alarmGas;
    map['h2Gas'] = null == h2Gas ? 0 : h2Gas;
    map['ch4Gas'] = null == ch4Gas ? 0 : ch4Gas;
    map['time'] = null == time ? '' : time;
    map['site'] = null == site ? '' : site;
    return map;
  }
}

/// 10-报警器
// class ObAlarm {
//   double alarm; // 报警器，1-报警，0-不报警
//   String site; // 站点
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['alarm'] = null == alarm ? 0 : alarm;
//     map['time'] = null == time ? '' : time;
//     map['site'] = null == site ? '' : site;
//     return map;
//   }
// }

/// 11-粗管阀温度
// class ObCrudeTEM {
//   double crudeTem; // 粗管温度
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['crudeTem'] = null == crudeTem ? 0 : crudeTem;
//     map['time'] = null == time ? '' : time;
//     return map;
//   }
// }

/// 12-粗管阀压力
// class ObCrudePRE {
//   double crudePre; // 粗管压力
//   String time; // 更新时间

//   Map toJson() {
//     Map map = new Map();
//     map['crudePre'] = null == crudePre ? 0 : crudePre;
//     map['time'] = null == time ? '' : time;
//     return map;
//   }
// }

/// 13-天然气能量信息
class ObEnergy {
  double qcEnergy; // 能量
  double qcVolumeCalorific; // 体积发热量
  double qcMolar; // 摩尔质量
  double qcMassCalorific; // 质量发热量
  int qcInterval; // 间隔秒

  Map toJson() {
    Map map = new Map();
    map['qcEnergy'] = null == qcEnergy ? 0 : qcEnergy;
    map['qcVolumeCalorific'] =
        null == qcVolumeCalorific ? 0 : qcVolumeCalorific;
    map['qcMolar'] = null == qcMolar ? 0 : qcMolar;
    map['qcMassCalorific'] = null == qcMassCalorific ? 0 : qcMassCalorific;
    map['qcInterval'] = null == qcInterval ? 0 : qcInterval;
    return map;
  }
}
