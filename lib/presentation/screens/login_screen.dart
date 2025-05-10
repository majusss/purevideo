import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_event.dart';
import 'package:purevideo/presentation/widgets/re_captcha.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final SupportedService service;

  const LoginScreen({super.key, required this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _captchaToken;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logowanie do ${widget.service.displayName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Login',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać login';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proszę podać hasło';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GoogleReCaptcha(
                siteKey: '6LcQs24iAAAAALFibpEQwpQZiyhOCn-zdc-eFout',
                url: 'https://filman.cc',
                onToken: (token) {
                  setState(() {
                    _captchaToken = token;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _handleSubmit,
                child: const Text('Zaloguj'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_captchaToken == null) {
      return getIt<ReCaptchaBloc>().add(const ReCaptchaShown());
    }
    if (_formKey.currentState!.validate()) {
      context.read<AccountsBloc>().add(
        SignInRequested(
          service: widget.service,
          email: _emailController.text,
          password: _passwordController.text,
          captcha: _captchaToken!,
        ),
      );
      context.pop();
    }
  }
}
