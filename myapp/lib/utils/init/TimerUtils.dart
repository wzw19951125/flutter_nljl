/// 延时刷新页面的工具类
/// Created in 2021-09-08 14:24:44 by YinRH
// class TimerUtils {
//   int mTime = 0;
//
//   /// 执行
//   /// [seconds] 延时秒数，小于5秒时，按照5秒处理
//   /// [cb] 回调方法
//   void execute(int seconds, Function cb) {
//     if (seconds < 5) seconds = 5;
//     int time = this.nowTime();
//     if (time - this.mTime > seconds * 1000) {
//       this.mTime = time;
//       if (null != cb) cb();
//     }
//   }
//
//   /// 获取系统时间，毫秒数
//   int nowTime() {
//     return DateTime.now().millisecondsSinceEpoch;
//   }
// }
