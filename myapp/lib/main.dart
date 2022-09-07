import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cool_ui/cool_ui.dart';

import 'package:myapp/pages/work/WorkControlPage.dart';
import 'package:myapp/utils/db/DbUtils.dart';

void main() async {
  await DbUtils.instance.init();
  await DbUtils.instance.timer();
  await NumberKeyboard.register();
  runApp(KeyboardRootWidget(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '能量计量物联网网关',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: MyHomePage(),
      localizationsDelegates: [
        //此处
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        //此处
        const Locale('zh', 'CH'),
      ],
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return KeyboardMediaQuery(
      child: Builder(builder: (builder) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: WorkControlPage(),
        );
      }),
    );
  }
}
