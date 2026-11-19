import 'package:flutter/widgets.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Screen for collecting user name in the manual onboarding flow.
///
/// Supports text editing and voice dictation via constructor callback [onVoiceInput].
class const UserNameScreen({
  required final ValueChanged<String> onContinue,
  super.key,
  final String? initialName,
  final VoidCallback? onVoiceInput,
  final VoidCallback? onBack,
}) extends StatefulWidget {
  @override
  State<UserNameScreen> createState() => _UserNameScreenState();
}

class _UserNameScreenState extends State<UserNameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void didUpdateWidget(UserNameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialName != oldWidget.initialName &&
        widget.initialName != null &&
        _controller.text.isEmpty) {
      _controller.text = widget.initialName!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleVoiceDictation() {
    if (widget.onVoiceInput != null) {
      widget.onVoiceInput!();
    } else {
      // Default voice input simulation fallback when no provider is connected
      setState(() {
        _controller.text = 'Alex Morgan';
      });
    }
  }

  Widget _buildMicButton() {
    return ArcaButton(
      label: 'Dictate',
      icon: const PhosphorIcon(PhosphorIconsBold.microphone, size: 18),
      variant: .secondary,
      semanticsLabel: 'Dictate name with voice',
      onPressed: _handleVoiceDictation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Profile Setup',
        leading: NullableBuilder(
          widget.onBack,
          builder: (context, back) => ArcaButton(
            label: 'Back',
            icon: const PhosphorIcon(PhosphorIconsBold.arrowLeft, size: 16),
            variant: .ghost,
            semanticsLabel: 'Go back',
            onPressed: back,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: ArcaSpacing.lg,
            vertical: ArcaSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              const Text('Personal Identity', style: ArcaTypography.display),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Enter your name to label your primary health vault. This remains encrypted exclusively on your hardware.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaTextField(
                controller: _controller,
                label: 'FULL NAME',
                hintText: 'e.g. Alex Morgan',
                trailing: _buildMicButton(),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Complete Setup & Create Vault',
                icon: const PhosphorIcon(
                  PhosphorIconsBold.arrowRight,
                  size: 18,
                ),
                variant: .primary,
                semanticsLabel: 'Complete onboarding and create vault',
                onPressed: () {
                  final text = _controller.text.trim();
                  widget.onContinue(text.isNotEmpty ? text : 'Alex');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
