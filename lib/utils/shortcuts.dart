import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Intents
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class SkipBackIntent extends Intent {
  const SkipBackIntent();
}

class SkipForwardIntent extends Intent {
  const SkipForwardIntent();
}

class MarkStartIntent extends Intent {
  const MarkStartIntent();
}

class MarkEndIntent extends Intent {
  const MarkEndIntent();
}

class CancelAnnotationIntent extends Intent {
  const CancelAnnotationIntent();
}

class SaveAnnotationsIntent extends Intent {
  const SaveAnnotationsIntent();
}

// Global shortcut mapping
final Map<ShortcutActivator, Intent> appShortcuts = {
  const SingleActivator(LogicalKeyboardKey.space): const PlayPauseIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowLeft): const SkipBackIntent(),
  const SingleActivator(LogicalKeyboardKey.arrowRight):
      const SkipForwardIntent(),
  const SingleActivator(LogicalKeyboardKey.bracketLeft):
      const MarkStartIntent(),
  const SingleActivator(LogicalKeyboardKey.bracketRight): const MarkEndIntent(),
  const SingleActivator(LogicalKeyboardKey.escape):
      const CancelAnnotationIntent(),
  const SingleActivator(LogicalKeyboardKey.keyS, control: true):
      const SaveAnnotationsIntent(),
};
