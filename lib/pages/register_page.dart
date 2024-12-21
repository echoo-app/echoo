import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../widgets/alert_dialog_helper.dart';
import '../services/state_manager.dart';
import '../l10n/strings.dart';
import '../pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('开始注册流程');
      print('用户名: ${_usernameController.text}');
      print('邀请码: ${_inviteCodeController.text.isEmpty ? "无" : _inviteCodeController.text}');

      final stateManager = Provider.of<StateManager>(context, listen: false);
      final dio = stateManager.createDio();
      final response = await dio.post(
        '/api/register',
        data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'invite_code': _inviteCodeController.text.isEmpty ? null : _inviteCodeController.text,
        },
      );

      print('注册响应状态码: ${response.statusCode}');
      print('注册响应内容: ${response.data}');

      if (!mounted) return;
      final lang = stateManager.selectedLanguage;
      final responseData = response.data;
      
      if (response.statusCode == 200 && responseData['message'] == 'Register success') {
        print('注册成功，开始登录');
        
        // 尝试登录
        final loginSuccess = await Provider.of<StateManager>(context, listen: false)
            .login(_usernameController.text, _passwordController.text);
        
        print('登录结果: ${loginSuccess ? "成功" : "失败"}');
        
        if (!mounted) return;
        
        if (loginSuccess) {
          print('登录成功，导航到主页');
          // 登录成功后直接导航到主页
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          print('登录失败，显示错误消息');
          // 如果登录失败，显示错误消息
          await AlertDialogHelper.showMessage(
            context,
            AppStrings.getString('loginFailed', lang),
          );
          // 返回登录页
          if (!mounted) return;
          Navigator.pop(context);
        }
      } else {
        print('注册失败，错误信息: ${responseData['error']}');
        String errorMessage = AppStrings.getString('registrationFailed', lang);
        final error = responseData['error']?.toString() ?? '';
        
        if (error.contains('UNIQUE constraint failed: users.username')) {
          errorMessage = AppStrings.getString('usernameExists', lang);
        }
        
        await AlertDialogHelper.showMessage(context, errorMessage);
      }
    } catch (e) {
      print('注册过程发生错误: $e');
      if (!mounted) return;
      final lang = Provider.of<StateManager>(context, listen: false).selectedLanguage;
      await AlertDialogHelper.showMessage(
        context,
        AppStrings.getString('registerFailed', lang),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateManager>(
      builder: (context, stateManager, child) {
        final lang = stateManager.selectedLanguage;
        
        return Scaffold(
          backgroundColor: const Color(0xFF090B10),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 32.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.getString('registerTitle', lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('username', lang),
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.getString('enterUsername', lang);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('password', lang),
                          labelStyle: const TextStyle(color: Colors.white70),
                          helperText: AppStrings.getString('passwordLength', lang),
                          helperStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.getString('enterPassword', lang);
                          }
                          if (value.length < 6) {
                            return AppStrings.getString('passwordTooShort', lang);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _inviteCodeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('inviteCode', lang),
                          labelStyle: const TextStyle(color: Colors.white70),
                          helperText: AppStrings.getString('inviteCodeHint', lang),
                          helperStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          errorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF39FF14),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF39FF14).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppStrings.getString('register', lang),
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }
}
