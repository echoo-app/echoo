import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_manager.dart';
import '../widgets/alert_dialog_helper.dart';
import '../l10n/strings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stateManager = Provider.of<StateManager>(context, listen: false);
      final success = await stateManager.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        if (!mounted) return;
        Navigator.pop(context, true); // 返回true表示登录成功
      } else {
        if (!mounted) return;
        AlertDialogHelper.showMessage(
          context,
          AppStrings.getString('invalidCredentials', stateManager.selectedLanguage),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final lang = Provider.of<StateManager>(context, listen: false).selectedLanguage;
      AlertDialogHelper.showMessage(
        context,
        AppStrings.getString('loginFailed', lang),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.getString('login', lang),
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white.withOpacity(0.5),
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
                              AppStrings.getString('login', lang),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
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
    super.dispose();
  }
}
