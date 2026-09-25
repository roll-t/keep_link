import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/security/presentation/controller/pin_verify_controller.dart';
import 'package:keep_link/features/security/presentation/widget/pin_verify_form.dart';

class PinVerifyPage extends GetView<PinVerifyController> {
  static const routeName = '/PinVerifyPage';

  const PinVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.mode.value;
      final title = mode == FromType.changePassword
          ? 'Đổi mã PIN'
          : 'Thiết lập mã PIN';

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: Utils.dimissKeyboard,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(title: title),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: .97,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: ConstrainedBox(
                          key: ValueKey(mode),
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: PinVerifyForm(
                            fromType: mode,
                            margin: EdgeInsets.zero,
                            autofocus: true,
                            obscureText: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }
}
