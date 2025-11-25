// dart
// file: 'lib/OTPScreen.dart'
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Components/Constants.dart';
import 'Confg/supabase.dart';

import 'Layout/Cubit/cubit.dart';
import 'Layout/MainScreen.dart';
import 'Services/PresenceManager.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, this.email});

  final String? email;

  OtpScreen copyWithEmail(String email) => OtpScreen(email: email);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isEditingEmail = false;

  final _digitControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _verifying = false;
  bool _resending = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    final initEmail = (widget.email ?? supabase.auth.currentUser?.email ?? '').trim();
    _emailController.text = initEmail;

    _isEditingEmail = initEmail.isEmpty;
    if (_isEditingEmail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocusNode.requestFocus();
      });
    }

    _emailController.addListener(() => setState(() {}));

    _startTimer();

    // Defer initial focus to first OTP box if email present
    if (initEmail.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String _collectCode() => _digitControllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPasted(value, index);
      return;
    }
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      // Defer focus change to avoid layout re-entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index + 1].requestFocus();
      });
    }
    if (value.isEmpty && index > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index - 1].requestFocus();
      });
    }
    setState(() {});
  }

  void _fillFromPasted(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < 6; i++) {
      final v = (i < digits.length) ? digits[i] : '';
      _digitControllers[i].text = v;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextEmpty = _digitControllers.indexWhere((c) => c.text.isEmpty);
      final idx = nextEmpty == -1 ? 5 : nextEmpty;
      _focusNodes[idx].requestFocus();
    });
    setState(() {});
  }

  Future<void> _verify() async {
    final email = _emailController.text.trim();
    final code = _collectCode();
    if (email.isEmpty || code.length != 6) return;

    setState(() => _verifying = true);
    try {
      // Adjust OTP type to your flow. Commonly OtpType.signup or OtpType.email.
      await supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) {
          context.read<AppCubit>().getPostsData(selectedCompoundId);
          context.read<AppCubit>().loadCompoundMembers(selectedCompoundId!);
          UserData = Supabase.instance.client.auth.currentSession?.user;
          userRole = Roles.values[UserData?.userMetadata?["role_id"]-1];
          AppCubit.get(context).verificationFilesUpload();
          AppCubit.get(context).signInSwitcher();
          return PresenceManager(child: MainScreen());
        }),
            (route) => false,
      );
    } catch (_) {
      // Keep UI minimal; add toast/snackbar if desired
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _secondsLeft > 0) return;

    setState(() => _resending = true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: email);
      _startTimer();
    } catch (_) {
      // Silent fail UI
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  bool get _canVerify =>
      _emailController.text.trim().isNotEmpty &&
          _digitControllers.every((c) => c.text.length == 1) &&
          !_verifying;

  Widget _buildOtpBoxes() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(6, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 44,
              child: TextField(
                controller: _digitControllers[i],
                focusNode: _focusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),

                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue,width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),),),
                onChanged: (v) => _onDigitChanged(i, v),
                onTap: () {
                  // Prevent selecting non-first empty
                  final firstEmpty = _digitControllers.indexWhere((c) => c.text.isEmpty);
                  if (firstEmpty != -1 && i > firstEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusNodes[firstEmpty].requestFocus();
                    });
                  }
                },
                onSubmitted: (_) {
                  if (i == 5 && _canVerify) _verify();
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompactEmailField() {
    final emailEmpty = _emailController.text.trim().isEmpty;
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    const hint = 'name@example.com';
    final value = _emailController.text.trim().isEmpty ? hint : _emailController.text.trim();

    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // Small horizontal padding + clamp to available space (matches parent 0.6 * width)
    final measured = painter.width + 6;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.6;
    final fieldWidth = measured.clamp(60.0, maxWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("We Just sent an Email",style: TextStyle(fontWeight: FontWeight.w700 ,fontSize: 20),),
        Text("Enter the security code we sent to",style: TextStyle(fontWeight: FontWeight.w400 ,fontSize: 16)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width:fieldWidth,
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                enabled: _isEditingEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration.collapsed(hintText: 'name@example.com'),
                onChanged: (_) => setState(() {}),
              ),
            ),

            IconButton(
              tooltip: _isEditingEmail ? 'Lock' : 'Edit',
              onPressed: () {
                setState(() {
                  _isEditingEmail = !_isEditingEmail;
                  if (_isEditingEmail) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _emailFocusNode.requestFocus();
                    });
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                });
              },
              icon: Icon(_isEditingEmail ? Icons.lock_open : Icons.edit),
            ),
            Icon(
              emailEmpty ? Icons.warning_amber_rounded : Icons.check_circle,
              color: emailEmpty ? Colors.orange : Colors.green,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailEmpty = _emailController.text.trim().isEmpty;

    return Directionality(
      textDirection: TextDirection.ltr, // Prevents null TextDirection issues
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify email')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 100,),
                    _buildCompactEmailField(),
                    const SizedBox(height: 8),

                    const SizedBox(height: 12),
                    _buildOtpBoxes(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _canVerify ? _verify : null,
                        child: _verifying
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Verify'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: (_resending || _secondsLeft > 0 || emailEmpty) ? null : _resend,
                      child: _resending
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        _secondsLeft > 0 ? 'Resend code in $_secondsLeft s' : 'Resend code',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
