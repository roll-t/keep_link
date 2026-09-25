import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:keep_link/core/services/backend/link_metadata_service.dart';
import 'package:keep_link/core/state/mixins/argument_handle_mixin_controller.dart';
import 'package:keep_link/core/utils/dialog_utils.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';
import 'package:keep_link/features/splash/presentation/controller/splash_controller.dart';

class DeepLinkController extends GetxController
    with ArgumentHandlerMixinController<SplashArg> {
  final Rx<MetaDataModel?> metaData = Rx(null);
  final RxBool isLoading = false.obs;
  String? deepLink;

  @override
  void onInit() {
    super.onInit();
    if (handleArgumentFromGet()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initDeepLink());
    }
  }

  void _initDeepLink() {
    deepLink = argsData?.deepLinkText;
    if (deepLink == null || deepLink!.isEmpty) return;
    fetchMetaData(deepLink!);
  }

  Future<void> fetchMetaData(String url) async {
    if (isLoading.value) return;
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    DialogUtils.showProgressDialog();
    update(['EXTRA_LINK_ID']);
    try {
      metaData.value = await LinkMetadataService.fetch(url);
    } catch (error, stackTrace) {
      log('Error fetching metadata: $error', stackTrace: stackTrace);
      metaData.value = LinkMetadataService.empty(url);
    } finally {
      isLoading.value = false;
      update(['EXTRA_LINK_ID']);
      if (Get.isDialogOpen == true) Get.back<void>();
    }
  }
}
