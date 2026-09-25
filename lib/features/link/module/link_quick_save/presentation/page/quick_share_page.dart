import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keep_link/core/config/theme/app_colors.dart';
import 'package:keep_link/core/config/theme/app_text_styles.dart';
import 'package:keep_link/core/presentation/extensions/colors.dart';
import 'package:keep_link/core/presentation/widgets/text/text_widget.dart';
import 'package:keep_link/features/link/application/incoming_link_save_service.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

enum QuickShareState { saving, saved, duplicate, error }

class QuickSharePage extends StatefulWidget {
  const QuickSharePage({super.key, required this.sharedText});

  final String sharedText;

  @override
  State<QuickSharePage> createState() => _QuickSharePageState();
}

class _QuickSharePageState extends State<QuickSharePage> {
  QuickShareState _state = QuickShareState.saving;
  LinkModel? _savedLink;
  String? _error;
  late final String? _incomingUrl = IncomingLinkSaveService.extractUrl(widget.sharedText);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  Future<void> _save() async {
    if (mounted) {
      setState(() {
        _state = QuickShareState.saving;
        _error = null;
      });
    }

    try {
      final result = await IncomingLinkSaveService.save(widget.sharedText);
      if (!mounted) return;
      setState(() {
        _savedLink = result.link;
        _state = result.status == IncomingLinkSaveStatus.duplicate
            ? QuickShareState.duplicate
            : QuickShareState.saved;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) await SystemNavigator.pop();
    } on IncomingLinkException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = QuickShareState.error;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = QuickShareState.error;
        _error = 'Không thể lưu link lúc này';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = _state == QuickShareState.error;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 326),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(scale: .94 + (.06 * value), child: child),
                ),
                child: Material(
                  color: AppColors.surface,
                  elevation: 16,
                  shadowColor: AppColors.black,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Image.asset(
                            'assets/icons/ic_logo_linkeep_full.png',
                            width: 54,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(20, 20, 20, isError ? 16 : 22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: TextWidget(
                                          text: _title,
                                          textStyle: AppTextStyle.bold16,
                                          color: AppColors.white,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        transitionBuilder: (child, animation) => ScaleTransition(
                                          scale: animation,
                                          child: FadeTransition(opacity: animation, child: child),
                                        ),
                                        child: _buildStatusIcon(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextWidget(
                                    text: _subtitle,
                                    textAlign: TextAlign.center,
                                    textStyle: AppTextStyle.regular10,
                                    color: AppColors.n70,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildLinkPreview(),
                                ],
                              ),
                            ),
                            if (isError) ...[
                              Divider(
                                height: 1,
                                thickness: 0.8,
                                color: AppColors.white.withOpacityCompat(0.08),
                              ),
                              SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: SystemNavigator.pop,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        child: Center(
                                          child: TextWidget(
                                            text: 'Đóng',
                                            size: 15,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.white.withOpacityCompat(0.75),
                                          ),
                                        ),
                                      ),
                                    ),
                                    VerticalDivider(
                                      width: 1,
                                      thickness: 0.8,
                                      color: AppColors.white.withOpacityCompat(0.08),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _save,
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(16),
                                        ),
                                        child: const Center(
                                          child: TextWidget(
                                            text: 'Thử lại',
                                            size: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryDim,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
  }

  Widget _buildStatusIcon() {
    switch (_state) {
      case QuickShareState.saving:
        return const SizedBox.square(
          key: ValueKey('saving'),
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDim),
        );
      case QuickShareState.saved:
        return _statusCircle(
          key: const ValueKey('saved'),
          color: AppColors.success,
          icon: Icons.check_rounded,
        );
      case QuickShareState.duplicate:
        return _statusCircle(
          key: const ValueKey('duplicate'),
          color: AppColors.primaryDim,
          icon: Icons.bookmark_added_rounded,
        );
      case QuickShareState.error:
        return _statusCircle(
          key: const ValueKey('error'),
          color: AppColors.error,
          icon: Icons.close_rounded,
        );
    }
  }

  Widget _statusCircle({required Key key, required Color color, required IconData icon}) {
    return Container(
      key: key,
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color.withOpacityCompat(0.18), shape: BoxShape.circle),
      child: Center(child: Icon(icon, color: color, size: 14)),
    );
  }

  Widget _buildLinkPreview() {
    final url = _savedLink?.metaDataModel?.url ?? _incomingUrl ?? widget.sharedText;
    final host = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacityCompat(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link_rounded, color: AppColors.primaryDim, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextWidget(
                  text: host.isEmpty ? 'Link được chia sẻ' : host,
                  textStyle: AppTextStyle.semiBold12,
                  color: AppColors.onSurface,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                TextWidget(
                  text: url,
                  textStyle: AppTextStyle.regular10,
                  color: AppColors.onSurfaceVariant,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _title => switch (_state) {
    QuickShareState.saving => 'Đang lưu link',
    QuickShareState.saved => 'Đã lưu link',
    QuickShareState.duplicate => 'Link đã tồn tại',
    QuickShareState.error => 'Lưu link thất bại',
  };

  String get _subtitle => switch (_state) {
    QuickShareState.saving => 'Linkeep đang tự động lấy thông tin liên kết',
    QuickShareState.saved => 'Đã thêm vào danh sách chưa phân loại',
    QuickShareState.duplicate => 'Link này đã có trong Linkeep',
    QuickShareState.error => _error ?? 'Vui lòng thử lại',
  };
}
