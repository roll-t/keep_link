import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/animation/app_entrance_animation.dart';
import 'package:keep_link/core/presentation/widgets/button/primary_button.dart';
import 'package:keep_link/core/presentation/widgets/tab/app_segmented_tab.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/simple_input_textfield.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';

class CategoryDialog extends StatefulWidget {
  static const String routeName = '/category_dialog';

  const CategoryDialog({super.key, this.isEditMode = false});

  final bool isEditMode;

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final CategoryController controller;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CategoryController>();
    _nameFocusNode = FocusNode();
    controller.prepareCategoryForm(isEditMode: widget.isEditMode);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _close() {
    if (controller.isCategorySaving.value) return;
    Utils.dimissKeyboard();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSaving = controller.isCategorySaving.value;

      return PopScope(
        canPop: !isSaving,
        child: Scaffold(
          backgroundColor: AppColors.black.withOpacityCompat(.72),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: Utils.dimissKeyboard,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: AppEntranceAnimation(
                    duration: const Duration(milliseconds: 480),
                    beginOffset: const Offset(0, .12),
                    beginScale: .94,
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.modalSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: .38),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .08),
                            blurRadius: 26,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isSaving),
                          const SizedBox(height: 18),

                          SimpleInputTextField(
                            controller: controller.categoryNameController,
                            focusNode: _nameFocusNode,
                            hintText: 'Enter category name'.tr,
                            errorText: controller.errorMess.value,
                            onChanged: (_) => controller.onChangeDismissError(),
                            onCompleted: (_) {
                              if (!isSaving) {
                                widget.isEditMode
                                    ? controller.updateCategory()
                                    : controller.addCategory();
                              }
                            },
                            enable: !isSaving,
                            maxLength: 45,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            suffixIcon: AppGetStorage.isCategorySecurity()
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _buildVisibilitySelector(isSaving),
                                    ),
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 76,
                              maxWidth: 76,
                              minHeight: 45,
                              maxHeight: 45,
                            ),
                            radius: 12,
                            height: 45,
                            backgroundColor: AppColors.inputSurface,
                            enableColor: AppColors.primaryContainer.withValues(
                              alpha: .12,
                            ),
                            focusedColor: AppColors.primaryDim,
                            hintColor: AppColors.onSurfaceVariant.withValues(
                              alpha: .48,
                            ),
                            textColor: AppColors.onSurface,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButtons(isSaving),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(bool isSaving) {
    return Row(
      children: [
        Expanded(
          child: TextWidget(
            text: widget.isEditMode ? 'Edit Category'.tr : 'Add Category'.tr,
            textStyle: AppTextStyle.semiBold20,
            color: AppColors.primaryDim,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: isSaving ? .45 : 1,
          child: IgnorePointer(
            ignoring: isSaving,
            child: Material(
              color: AppColors.primary.withValues(alpha: .1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _close,
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.onSurface,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          isMaxParent: true,
          text: widget.isEditMode ? 'Save'.tr : 'Add'.tr,
          isLoading: isSaving,
          onPressed: widget.isEditMode
              ? controller.updateCategory
              : controller.addCategory,
          backgroundColor: AppColors.primary,
          color: AppColors.white,
        ),
        if (widget.isEditMode) ...[
          const SizedBox(height: 10),
          PrimaryButton(
            isMaxParent: true,
            text: 'Delete'.tr,
            onPressed: isSaving ? null : controller.deleteCategory,
            backgroundColor: AppColors.background.withValues(alpha: .48),
            color: AppColors.error,
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilitySelector(bool isSaving) {
    final isPublic = controller.visibility.value == VisibilityStatus.public;

    return IgnorePointer(
      ignoring: isSaving,
      child: SizedBox(
        width: 68,
        height: 24,
        child: AppSegmentedTab(
          selectedIndex: isPublic ? 0 : 1,
          height: 24,
          padding: 2,
          borderRadius: 20,
          backgroundColor: AppColors.background.withValues(alpha: .52),
          borderColor: AppColors.white.withValues(alpha: .07),
          selectedColor: AppColors.primary,
          selectedGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBright, AppColors.primary],
          ),
          onChanged: (index) => controller.setVisibility(
            index == 0 ? VisibilityStatus.public : VisibilityStatus.private,
          ),
          tabs: [
            AppSegmentTabItem(
              label: '',
              semanticLabel: 'Public'.tr,
              icon: SizedBox.square(
                dimension: 16,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, 1.5),
                    child: Icon(Icons.public_rounded, size: 13),
                  ),
                ),
              ),
            ),
            AppSegmentTabItem(
              label: '',
              semanticLabel: 'Private'.tr,
              icon: SizedBox.square(
                dimension: 16,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, 1.5),
                    child: Icon(Icons.lock_rounded, size: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
