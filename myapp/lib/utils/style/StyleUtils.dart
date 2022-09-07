import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// 封装 Widget 的；工具类
/// Created in 2021-08-24 17:43:44 by YinRH
class StyleUtils {
  /// 颜色，0-标题，1-内容(白)，2-按钮，3-按钮(灰)，
  /// 4-报警/关(红)，5-报警(默认)，6-背景，7-开(绿)
  List<Color> colors = [
    Color.fromARGB(255, 220, 193, 0),
    Colors.white,
    Color.fromARGB(255, 78, 109, 153),
    Color.fromARGB(100, 217, 217, 217),
    Color.fromARGB(255, 230, 0, 12),
    Color.fromARGB(255, 0, 19, 73),
    Color.fromARGB(255, 30, 43, 82),
    Color.fromARGB(255, 137, 207, 2)
  ];

  /// 获取 TextStyle 对象，默认为‘微软雅黑’字体
  /// [size] 字体大小，[index] 字体颜色索引值
  TextStyle textStyle(double size, int index) {
    return TextStyle(fontSize: size, color: colors[index], fontFamily: 'Msyh');
  }

  /// 获取 ElevatedButton 按钮，普通
  /// [title] 标题，[size] 字体大小，[click] 点击事件
  ElevatedButton normal(String title, double size, Function click) {
    return this._button(title, size, 1, 2, click);
  }

  /// 获取 ElevatedButton 按钮，连接
  /// [type] 类型（0-tcp，1-gns），[connect] 是否已连接，[click] 点击事件
  ElevatedButton connect(int type, bool connect, Function click) {
    String title = '';
    int bgColor = 2;
    if (0 == type) {
      bgColor = connect ? 2 : 3;
      title = connect ? '已连接' : '未连接';
    } else {
      bgColor = connect ? 3 : 2;
      title = connect ? '断开' : '连接';
    }
    return this._button(title, 14, 1, bgColor, click);
  }

  /// 获取 ElevatedButton 按钮
  /// [title] 标题，[size] 字体大小，[txt] 字体颜色索引值，
  /// [bg] 背景颜色索引值， [click] 点击时间
  ElevatedButton _button(
      String title, double size, int txt, int bg, Function click) {
    return ElevatedButton(
      child: Container(
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: this.textStyle(size, txt),
        ),
      ),
      onPressed: () => click(),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(colors[bg]),
      ),
    );
  }

  /// 设置背景颜色，以及倒圆角
  /// [index] 颜色索引值，[radius] 圆角直径
  BoxDecoration radius(int index, double radius) {
    return BoxDecoration(
      color: this.colors[index],
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );
  }

  /// 设置边框，以及倒圆角
  /// [index] 颜色索引值，[radius] 圆角直径
  BoxDecoration border(int index, double radius) {
    return BoxDecoration(
      border: Border.all(width: 1, color: colors[index]),
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );
  }
}
