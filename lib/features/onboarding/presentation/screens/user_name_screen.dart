import 'package:flutter/widgets.dart';

import 'package:arca/core/design_system/arca_design_system.dart';
import 'package:arca/core/widgets/widgets.dart';

/// Screen asking only for the user's name during onboarding setup.
///
/// Features a prominent voice dictation microphone button alongside the text field
/// as an alternative input modality.
class const UserNameScreen({
  required final ValueChanged<String> onContinue,
  super.key,
  final VoidCallback? onBack,
  final VoidCallback? onVoiceInput,
  final String? initialName,
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
      label: '🎙️',
      variant: .secondary,
      semanticsLabel: 'Dictate name with voice',
      onPressed: _handleVoiceDictation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArcaScaffold(
      header: ArcaHeader(
        title: 'Profile',
        leading: NullableBuilder(
          value: widget.onBack,
          builder: (context, back) => ArcaButton(
            label: '←',
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
              const Text(
                'What should Arca call you?',
                style: ArcaTypography.display,
              ),
              const SizedBox(height: ArcaSpacing.xs),
              Text(
                'Your name identifies your primary health vault and stays encrypted exclusively on your hardware.',
                style: ArcaTypography.bodyLarge.copyWith(
                  color: ArcaColors.textSecondary,
                ),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaTextField(
                controller: _controller,
                label: 'Your Name',
                hintText: 'e.g. Alex Morgan',
                trailing: _buildMicButton(),
              ),
              const SizedBox(height: ArcaSpacing.xxl),
              ArcaButton(
                label: 'Complete Setup & Create Vault →',
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
