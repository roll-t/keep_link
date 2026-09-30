import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/config/constants/app_enum.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/data/cache/app_get_storage.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/animation/app_entrance_animation.dart';
import 'package:keep_link/core/presentation/widgets/tab/app_segmented_tab.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/core/presentation/widgets/text_field/simple_input_textfield.dart';
import 'package:keep_link/core/utils/utils.dart';
import 'package:keep_link/features/category/presentation/controller/category_controller.dart';

class CategoryDialog extends GetView<CategoryController> {
  static const String routeName = '/category_dialog';

  final bool isEditMode;

  const CategoryDialog({super.key, this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
    controller.ensureFormPrepared(isEditMode: isEditMode);

    return Obx(() {
      final isSaving = controller.isCategorySaving.value;

      return PopScope(
        canPop: !isSaving,
        child: Scaffold(
          backgroundColor: AppColors.black.withOpacityCompat(.72),
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isSaving ? null : controller.closeCategoryDialog,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: Utils.dimissKeyboard,
                    child: AppEntranceAnimation(
                      duration: const Duration(milliseconds: 480),
                      beginOffset: const Offset(0, .12),
                      beginScale: .94,
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 360),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(16),
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
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 18),
                                  SimpleInputTextField(
                                    controller: controller.categoryNameController,
                                    focusNode: controller.nameFocusNode,
                                    hintText: 'Enter category name'.tr,
                                    isShowBorder: false,
                                    errorText: controller.errorMess.value,
                                    onChanged: (_) => controller.onChangeDismissError(),
                                    onCompleted: (_) {
                                      if (!isSaving) {
                                        isEditMode
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
                                    backgroundColor: AppColors.navigationSurface,
                                    enableColor: AppColors.primaryContainer.withValues(alpha: .12),
                                    focusedColor: AppColors.primaryDim,
                                    hintColor: AppColors.onSurfaceVariant.withValues(alpha: .48),
                                    textColor: AppColors.onSurface,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 0.8,
                              color: AppColors.white.withOpacityCompat(0.08),
                            ),
                            SizedBox(height: 48, child: _buildActionButtons(isSaving)),
                          ],
                        ),
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

  Widget _buildHeader() {
    return TextWidget(
      text: isEditMode ? 'Edit Category'.tr : 'Add Category'.tr,
      textStyle: AppTextStyle.bold18,
      color: AppColors.primaryDim,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(bool isSaving) {
    if (isEditMode) {
      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: isSaving ? null : controller.deleteCategory,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
              child: Center(
                child: TextWidget(
                  text: 'Delete'.tr,
                  size: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 0.8, color: AppColors.white.withOpacityCompat(0.08)),
          Expanded(
            child: InkWell(
              onTap: isSaving ? null : controller.updateCategory,
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
              child: Center(
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : TextWidget(
                        text: 'Save'.tr,
                        size: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: isSaving ? null : controller.closeCategoryDialog,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
            child: Center(
              child: TextWidget(
                text: 'Cancel'.tr,
                size: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.white.withOpacityCompat(0.75),
              ),
            ),
          ),
        ),
        VerticalDivider(width: 1, thickness: 0.8, color: AppColors.white.withOpacityCompat(0.08)),
        Expanded(
          child: InkWell(
            onTap: isSaving ? null : controller.addCategory,
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : TextWidget(
                      text: 'Add'.tr,
                      size: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ),
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
              icon: const SizedBox.square(
                dimension: 16,
                child: Center(child: Icon(Icons.public_rounded, size: 13)),
              ),
            ),
            AppSegmentTabItem(
              label: '',
              semanticLabel: 'Private'.tr,
              icon: const SizedBox.square(
                dimension: 16,
                child: Center(child: Icon(Icons.lock_rounded, size: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
