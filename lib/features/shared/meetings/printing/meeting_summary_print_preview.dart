import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/app_colors.dart';
import '../../../../translations/app_localizations.dart';
import 'meeting_summary_printer.dart';

class MeetingSummaryPrintPreview extends StatefulWidget {
  const MeetingSummaryPrintPreview({
    super.key,
    required this.document,
    required this.name,
    required this.title,
  });

  final String document;
  final String name;
  final String title;

  @override
  State<MeetingSummaryPrintPreview> createState() =>
      _MeetingSummaryPrintPreviewState();
}

class _MeetingSummaryPrintPreviewState
    extends State<MeetingSummaryPrintPreview> {
  WebViewController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _printing = false;
  int _generation = 0;
  Timer? _timeout;

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _timeout?.cancel();
    setState(() {
      _ready = false;
      _failed = false;
      _controller = null;
    });
    try {
      final controller = WebViewController();
      if (controller.platform is AndroidWebViewController) {
        final android = controller.platform as AndroidWebViewController;
        await android.setUseWideViewPort(true);
        await android.setTextZoom(100);
      }
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.white);
      await controller.enableZoom(true);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url == 'about:blank' ||
                  request.url.startsWith('data:text/html')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true &&
                mounted &&
                generation == _generation) {
              setState(() => _failed = true);
            }
          },
          onPageFinished: (_) => unawaited(_awaitReady(controller, generation)),
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() => _controller = controller);
      _timeout = Timer(const Duration(seconds: 20), () {
        if (mounted && generation == _generation && !_ready) {
          setState(() => _failed = true);
        }
      });
      // Fit the A4-width document to the phone; pinch zoom remains available.
      await controller.loadHtmlString(
        widget.document.replaceFirst('width=794, initial-scale=1', 'width=794'),
      );
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }

  Future<void> _awaitReady(WebViewController controller, int generation) async {
    try {
      for (var attempt = 0; attempt < 150; attempt++) {
        if (!mounted || generation != _generation || _failed || _ready) return;
        final result = await controller.runJavaScriptReturningResult(
          'window.__meetingPrintReady === true',
        );
        if (!mounted || generation != _generation || _failed) return;
        if (result == true || result == 'true') {
          _timeout?.cancel();
          setState(() => _ready = true);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (mounted && generation == _generation) setState(() => _failed = true);
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }

  Future<void> _print() async {
    if (!_ready || _printing) return;
    // Release the preview platform view before creating the native print view.
    // Keeping both document renderers alive can exhaust smaller devices.
    _generation++;
    _timeout?.cancel();
    setState(() {
      _printing = true;
      _controller = null;
      _ready = false;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      // Print the same original document used for preview, with its A4 rules.
      await MeetingSummaryPrinter.printDocument(
        widget.document,
        name: widget.name,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('meetingSummaryPrintError'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _printing = false);
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = AppColors.isDark(context);
    final accent = AppColors.accent(context);
    final surface = AppColors.cardBackground(context);
    return Scaffold(
      backgroundColor: dark
          ? AppColors.darkBackground
          : const Color(0xFFF1F4F9),
      appBar: AppBar(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.primaryText(context),
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(),
        titleSpacing: 0,
        title: Text(
          l10n.text('meetingSummaryPrintPreview'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton.icon(
              key: const ValueKey('meeting-summary-confirm-print'),
              onPressed: _ready && !_failed && !_printing ? _print : null,
              icon: _printing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 18),
              label: Text(l10n.text('meetingSummaryPrintAction')),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              decoration: BoxDecoration(
                color: surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border(context)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: accent,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title.isEmpty ? widget.name : widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _DocumentChip(
                              icon: Icons.crop_portrait_outlined,
                              label: 'A4',
                            ),
                            _DocumentChip(
                              icon: Icons.description_outlined,
                              label: l10n.text('meetingSummaryPortrait'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _failed
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.mutedText,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.text('meetingSummaryPrintError'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.text),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _load,
                                  child: Text(l10n.text('retry')),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            if (_controller != null)
                              WebViewWidget(controller: _controller!),
                            if (!_ready)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pinch_outlined,
                    size: 15,
                    color: AppColors.secondaryText(context),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.text('meetingSummaryPreviewZoom'),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.subtleBackground(context),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.secondaryText(context)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.secondaryText(context),
          ),
        ),
      ],
    ),
  );
}
