import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'ollama_service.dart';
import '../config.dart';

enum ServiceOption { echoo, ollama }

class StateManager extends ChangeNotifier {
  static final StateManager _instance = StateManager._internal();
  factory StateManager() => _instance;

  late SharedPreferences _prefs;
  late final OllamaService _ollamaService;
  static String get baseUrl => Config.apiBaseUrl;
  static const String tokenKey = 'auth_token';
  static const String encryptionKeyKey = 'encryption_key';
  static const String encryptionIvKey = 'encryption_iv';
  static const String languageKey = 'selected_language';
  
  ServiceOption _selectedService = ServiceOption.echoo;
  String _selectedLanguage = 'en'; // 默认英文
  String _selectedModel = '';
  String _ollamaAddress = 'http://localhost:11434';
  String _prompt = '';
  double _fontSize = 16.0;

  bool _isLoggedIn = false;
  String? _username;
  int? _userId;
  int _apiCalls = 0;
  String _inviteCode = '';
  bool _isVip = false;
  String? _vipPaymentUrl;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  int? _selectedMessageIndex;

  StateManager._internal() {
    _ollamaService = OllamaService(this);
    _initPreferences();
  }

  // 加密相关
  late final encrypt.Key _encryptionKey;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  // 初始化加密
  Future<void> _initEncryption() async {
    try {
      // 获取或生成加密密钥
      String? savedKey = _prefs.getString(encryptionKeyKey);
      String? savedIv = _prefs.getString(encryptionIvKey);
      
      if (savedKey == null || savedIv == null) {
        // 生成新的密钥和 IV
        final key = encrypt.Key.fromSecureRandom(32);
        final iv = encrypt.IV.fromSecureRandom(16);
        
        savedKey = base64Encode(key.bytes);
        savedIv = base64Encode(iv.bytes);
        
        await _prefs.setString(encryptionKeyKey, savedKey);
        await _prefs.setString(encryptionIvKey, savedIv);
      }

      // 初始化加密组件
      _encryptionKey = encrypt.Key(base64Decode(savedKey));
      _iv = encrypt.IV(base64Decode(savedIv));
      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      
      print('加密组件初始化成功');
    } catch (e) {
      print('初始化加密组件失败: $e');
      // 如果出错，重新生成密钥和 IV
      await _prefs.remove(encryptionKeyKey);
      await _prefs.remove(encryptionIvKey);
      await _initEncryption();
    }
  }

  // 加密消息
  String _encryptMessage(String message) {
    return _encrypter.encrypt(message, iv: _iv).base64;
  }

  // 解密消息
  String _decryptMessage(String encryptedMessage) {
    try {
      return _encrypter.decrypt64(encryptedMessage, iv: _iv);
    } catch (e) {
      print('解密失败: $e');
      try {
        // 尝试作为 JSON 字符串解析
        jsonDecode(encryptedMessage);
        return encryptedMessage; // 如果是有效的 JSON，说明是旧的未加密消息
      } catch (_) {
        print('不是有效的 JSON 格式，可能是损坏的加密数据');
        return ''; // 返回空字符串，避免显示损坏的数据
      }
    }
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _initEncryption();
    
    // 读取保存的语言设置
    _selectedLanguage = _prefs.getString(languageKey) ?? 'en';
    
    // 读取保存的服务设置，默认使用 Echoo
    final savedService = _prefs.getString('selectedService');
    if (savedService != null && savedService == 'ServiceOption.ollama') {
      _selectedService = ServiceOption.ollama;
      _selectedModel = _prefs.getString('selectedModel') ?? '';
    } else {
      _selectedService = ServiceOption.echoo;
    }

    _ollamaAddress = _prefs.getString('ollamaAddress') ?? 'http://localhost:11434';
    _prompt = _prefs.getString('prompt') ?? '';
    _fontSize = _prefs.getDouble('fontSize') ?? 16.0;
    _isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
    _username = _prefs.getString('username');
    _userId = _prefs.getInt('userId');
    _apiCalls = _prefs.getInt('apiCalls') ?? 0;
    _isVip = _prefs.getBool('isVip') ?? false;
    _inviteCode = _prefs.getString('inviteCode') ?? '';

    // 读取并解密消息
    final savedMessages = _prefs.getString('messages');
    if (savedMessages != null) {
      try {
        final decryptedMessages = _decryptMessage(savedMessages);
        final List<dynamic> decodedMessages = jsonDecode(decryptedMessages);
        _messages = decodedMessages.map((msg) => Map<String, dynamic>.from(msg)).toList();
      } catch (e) {
        print('读取消息失败: $e');
        _messages = [];
      }
    }

    // 检查是否有保存的token
    final token = await getToken();
    if (token != null && _username != null) {
      _isLoggedIn = true;
      refreshUserInfo();
    } else {
      // 如果没有token，清除登录状态
      logout();
    }

    notifyListeners();
  }

  Future<void> _saveMessages() async {
    try {
      final messagesJson = jsonEncode(_messages);
      final encryptedMessages = _encryptMessage(messagesJson);
      await _prefs.setString('messages', encryptedMessages);
      notifyListeners();
    } catch (e) {
      print('保存消息失败: $e');
    }
  }

  ServiceOption get selectedService => _selectedService;
  String get selectedModel => _selectedModel;
  String get selectedLanguage => _selectedLanguage;
  String get ollamaAddress => _ollamaAddress;
  String get prompt => _prompt;
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  int? get userId => _userId;
  int? get selectedMessageIndex => _selectedMessageIndex;
  int get apiCalls => _apiCalls;
  String get inviteCode => _inviteCode;
  bool get isVip => _isVip;
  String? get vipPaymentUrl => _vipPaymentUrl;

  Future<bool> activateVip(String code) async {
    try {
      final headers = await getAuthHeaders();
      final dio = createDio();
      dio.options.headers.addAll(headers);
      
      final response = await dio.post(
        '/api/users/vip/activate',
        data: {
          'activation_code': code,
        },
      );

      if (response.statusCode == 200) {
        final user = response.data;
        _isVip = user['is_vip'] ?? false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('激活VIP失败: $e');
      return false;
    }
  }

  // Token管理
  Future<String?> getToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(tokenKey);
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未找到认证token，请重新登录');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void updateSettings({
    ServiceOption? service,
    String? model,
    String? ollamaAddress,
    String? prompt,
    double? fontSize,
    String? language,
  }) async {
    if (service != null && service != _selectedService) {
      _selectedService = service;
      await _prefs.setString('selectedService', 'ServiceOption.${service.name}');
    }
    
    if (model != null) {
      _selectedModel = model;
      await _prefs.setString('selectedModel', model);
    }
    
    if (ollamaAddress != null) {
      _ollamaAddress = ollamaAddress;
      _prefs.setString('ollamaAddress', ollamaAddress);
    }

    if (prompt != null) {
      _prompt = prompt;
      _prefs.setString('prompt', prompt);
    }

    if (fontSize != null) {
      _fontSize = fontSize;
      _prefs.setDouble('fontSize', fontSize);
    }

    if (language != null) {
      _selectedLanguage = language;
      _prefs.setString(languageKey, language);
    }
    
    notifyListeners();
  }

  Future<String?> refreshVipPaymentUrl() async {
    try {
      final headers = await getAuthHeaders();
      final dio = createDio();
      dio.options.headers.addAll(headers);
      
      final response = await dio.get('/api/vip/payment-url');

      if (response.statusCode == 200) {
        final data = response.data;
        _vipPaymentUrl = data['payment_url'];
        notifyListeners();
        return _vipPaymentUrl;
      }
      return null;
    } catch (e) {
      print('获取支付链接失败: $e');
      return null;
    }
  }

  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn || _username == null) return;

    try {
      final headers = await getAuthHeaders();
      final dio = createDio();
      dio.options.headers.addAll(headers);
      
      final response = await dio.get('/api/user/$_username');

      if (response.statusCode == 200) {
        final user = response.data;
        await updateUserInfo(
          userId: user['id'],
          apiCalls: user['api_calls'] ?? 0,
          inviteCode: user['invite_code'] ?? '',
          isVip: user['is_vip'] ?? false,
        );
        
        // 同时刷新支付链接
        await refreshVipPaymentUrl();
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      print('刷新用户信息失败: $e');
      await logout();
    }
  }

  Future<void> updateUserInfo({
    int? userId,
    int? apiCalls,
    String? inviteCode,
    bool? isVip,
  }) async {
    if (userId != null) {
      _userId = userId;
      await _prefs.setInt('userId', userId);
    }
    
    if (apiCalls != null) {
      _apiCalls = apiCalls;
      await _prefs.setInt('apiCalls', apiCalls);
    }

    if (inviteCode != null) {
      _inviteCode = inviteCode;
      await _prefs.setString('inviteCode', inviteCode);
    }

    if (isVip != null) {
      _isVip = isVip;
      await _prefs.setBool('isVip', isVip);
    }
    
    notifyListeners();
  }

  Future<void> updateApiCalls(int newApiCalls) async {
    _apiCalls = newApiCalls;
    await _prefs.setInt('apiCalls', newApiCalls);
    notifyListeners();
  }

  Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 配置dio忽略SSL证书验证
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };

    return dio;
  }

  Future<bool> login(String username, String password) async {
    print('开始登录流程: $username');
    // 先清除之前的登录状态
    await logout();
    
    try {
      final dio = createDio();
      final response = await dio.post(
        '/api/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('登录响应状态码: ${response.statusCode}');
      print('登录响应内容: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final user = responseData['user'];
        final token = responseData['token'];
        final vipPaymentUrl = responseData['vip_payment_url'];
        
        print('获取到用户信息: ${user.toString()}');
        _vipPaymentUrl = vipPaymentUrl;
        
        await saveToken(token);
        print('Token已保存');
        
        _isLoggedIn = true;
        _username = username;
        await _prefs.setBool('isLoggedIn', true);
        await _prefs.setString('username', username);
        print('基本用户信息已保存');
        
        await updateUserInfo(
          userId: user['id'],
          apiCalls: user['api_calls'] ?? 0,
          inviteCode: user['invite_code'] ?? '',
          isVip: user['is_vip'] ?? false,
        );
        print('用户详细信息已更新');
        
        notifyListeners();
        print('登录成功');
        return true;
      }
      
      print('登录失败，状态码: ${response.statusCode}');
      // 登录失败，确保状态是清除的
      await logout();
      return false;
    } catch (e) {
      print('登录过程发生错误: $e');
      // 发生错误，确保状态是清除的
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = null;
    _userId = null;
    _apiCalls = 0;
    _isVip = false;
    _vipPaymentUrl = null;
    _inviteCode = '';
    await _prefs.setBool('isLoggedIn', false);
    await _prefs.remove('username');
    await _prefs.remove('userId');
    await _prefs.remove('apiCalls');
    await _prefs.remove('isVip');
    await _prefs.remove('inviteCode');
    await clearToken();
    notifyListeners();
  }

  void replaceMessages(List<Map<String, dynamic>> newMessages) {
    _messages = newMessages;
    _selectedMessageIndex = null;
    _saveMessages();
  }

  void addMessage(
    String content, {
    required bool isUser,
    double? cost,
    double? actualCost,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
  }) {
    final message = {
      'role': isUser ? 'user' : 'assistant',
      'content': content,
      if (!isUser) ...{
        if (cost != null) 'cost': cost,
        if (actualCost != null) 'actual_cost': actualCost,
        if (promptTokens != null) 'prompt_tokens': promptTokens,
        if (completionTokens != null) 'completion_tokens': completionTokens,
        if (totalTokens != null) 'total_tokens': totalTokens,
      },
    };
    
    _messages.add(message);
    _selectedMessageIndex = null;
    _saveMessages();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _selectedMessageIndex = null;
    _saveMessages();
  }

  void removeMessageAtIndex(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeAt(index);
      _selectedMessageIndex = null;
      _saveMessages();
    }
  }

  void setSelectedMessageIndex(int? index) {
    if (_selectedMessageIndex != index) {
      _selectedMessageIndex = index;
      notifyListeners();
    }
  }
}
