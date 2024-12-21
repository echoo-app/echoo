import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io' show Platform;
import 'pages/home_page.dart';
import 'services/state_manager.dart';

class PhoneSimulator {
  // 桌面端固定尺寸（16:9 比例）
  static const double desktopWidth = 360.0;
  static const double desktopHeight = 640.0;

  // 判断是否为桌面平台
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 StateManager
  final stateManager = StateManager();

  if (PhoneSimulator.isDesktop) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: const Size(PhoneSimulator.desktopWidth, PhoneSimulator.desktopHeight),
      minimumSize: const Size(PhoneSimulator.desktopWidth, PhoneSimulator.desktopHeight),
      maximumSize: const Size(PhoneSimulator.desktopWidth, PhoneSimulator.desktopHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      fullScreen: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setResizable(false);
      await windowManager.setFullScreen(false);
    });
  }

  runApp(
    ChangeNotifierProvider.value(
      value: stateManager,
      child: const EchooApp(),
    ),
  );
}

class EchooApp extends StatefulWidget {
  const EchooApp({super.key});

  @override
  _EchooAppState createState() => _EchooAppState();
}

class _EchooAppState extends State<EchooApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (PhoneSimulator.isDesktop) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (PhoneSimulator.isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echoo',
      supportedLocales: const [
        Locale('zh', ''), // 中文
        Locale('en', ''), // 英文
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF39FF14);
            }
            return Colors.transparent;
          }),
          overlayColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color(0xFF39FF14).withOpacity(0.1);
            }
            return Colors.transparent;
          }),
        ),
        splashColor: const Color(0xFF39FF14).withOpacity(0.1),
        highlightColor: const Color(0xFF39FF14).withOpacity(0.1),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      home: const ResponsiveLayout(),
    );
  }

  @override
  void onWindowEnterFullScreen() async {
    if (PhoneSimulator.isDesktop) {
      await windowManager.setFullScreen(false);
    }
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // 桌面端使用固定尺寸
    if (PhoneSimulator.isDesktop) {
      return Container(
        width: PhoneSimulator.desktopWidth,
        height: PhoneSimulator.desktopHeight,
        decoration: BoxDecoration(
          color: Color(0xFF090B10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const HomePage(),
      );
    }
    
    // 移动端使用响应式布局
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Color(0xFF090B10),
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: const HomePage(),
        );
      },
    );
  }
}
