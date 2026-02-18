part of 'package:rich_form_field/rich_form_field.dart';

/// Controls how plain-text list markers are displayed in read-only widgets.
enum RichTextListRenderMode {
  /// Keeps list markers as stored plain text (`- item`).
  literal,

  /// Renders list markers as bullets (`• item`).
  bullets,
}

/// Resolves a custom style key into an optional [TextStyle].
typedef RichTextCustomStyleResolver =
    TextStyle? Function(String key, TextStyle base);

/// Displays rich text as a non-selectable widget.
///
/// Accepts either [encoded] text that is decoded using [codec], or a
/// pre-parsed [formatResult].
///
/// Example:
/// ```dart
/// RichStyledText(encoded: '<p><b>Hello</b> world</p>')
/// RichStyledText(encoded: 'Just plain text')
/// ```
class RichStyledText extends StatelessWidget {
  /// Creates a read-only rich-text widget.
  ///
  /// Provide either [encoded] or [formatResult].
  const RichStyledText({
    super.key,
    this.encoded,
    this.formatResult,
    this.codec = const HtmlRichTextCodec(),
    this.customStyles = const [],
    this.customStyleResolver,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textScaler,
    this.locale,
    this.strutStyle,
    this.listRenderMode = RichTextListRenderMode.literal,
  }) : assert(
         encoded != null || formatResult != null,
         'Provide encoded or formatResult.',
       );

  /// Creates a read-only rich-text widget from a pre-decoded format result.
  const RichStyledText.fromResult({
    super.key,
    required RichTextFormatResult result,
    this.customStyles = const [],
    this.customStyleResolver,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.textScaler,
    this.locale,
    this.strutStyle,
    this.listRenderMode = RichTextListRenderMode.literal,
  }) : formatResult = result,
       encoded = null,
       codec = const HtmlRichTextCodec();

  /// Raw encoded content to decode and render.
  final String? encoded;

  /// Pre-decoded rich-text value to render.
  final RichTextFormatResult? formatResult;

  /// Codec used to decode [encoded] when [formatResult] is not provided.
  final RichTextCodec codec;

  /// Custom style definitions used for fallback style builders.
  final Iterable<RichTextCustomStyle> customStyles;

  /// Optional callback that maps custom style keys to concrete text styles.
  final RichTextCustomStyleResolver? customStyleResolver;

  /// Base text style for rendering.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Text direction override for this widget.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line boundaries.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// Maximum number of lines for the rendered text.
  final int? maxLines;

  /// Text scaling configuration.
  final TextScaler? textScaler;

  /// Locale override for text rendering.
  final Locale? locale;

  /// Strut style used for line height and vertical metrics.
  final StrutStyle? strutStyle;

  /// Controls how list markers are displayed.
  final RichTextListRenderMode listRenderMode;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final resolved = _resolveFormatResult(encoded, formatResult, codec);
    final span = _buildRichStyledTextSpan(
      result: resolved,
      baseStyle: effectiveStyle,
      customStyles: customStyles,
      customStyleResolver: customStyleResolver,
      listRenderMode: listRenderMode,
    );

    return Text.rich(
      span,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
    );
  }
}

/// Displays rich text as a selectable widget.
///
/// Example:
/// ```dart
/// RichSelectableStyledText(
///   encoded: '<ul><li>First</li><li>Second</li></ul>',
///   listRenderMode: RichTextListRenderMode.bullets,
/// )
/// ```
class RichSelectableStyledText extends StatelessWidget {
  /// Creates a selectable read-only rich-text widget.
  ///
  /// Provide either [encoded] or [formatResult].
  const RichSelectableStyledText({
    super.key,
    this.encoded,
    this.formatResult,
    this.codec = const HtmlRichTextCodec(),
    this.customStyles = const [],
    this.customStyleResolver,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.minLines,
    this.textScaler,
    this.strutStyle,
    this.focusNode,
    this.autofocus = false,
    this.listRenderMode = RichTextListRenderMode.literal,
  }) : assert(
         encoded != null || formatResult != null,
         'Provide encoded or formatResult.',
       );

  /// Creates a selectable rich-text widget from a pre-decoded format result.
  const RichSelectableStyledText.fromResult({
    super.key,
    required RichTextFormatResult result,
    this.customStyles = const [],
    this.customStyleResolver,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.maxLines,
    this.minLines,
    this.textScaler,
    this.strutStyle,
    this.focusNode,
    this.autofocus = false,
    this.listRenderMode = RichTextListRenderMode.literal,
  }) : formatResult = result,
       encoded = null,
       codec = const HtmlRichTextCodec();

  /// Raw encoded content to decode and render.
  final String? encoded;

  /// Pre-decoded rich-text value to render.
  final RichTextFormatResult? formatResult;

  /// Codec used to decode [encoded] when [formatResult] is not provided.
  final RichTextCodec codec;

  /// Custom style definitions used for fallback style builders.
  final Iterable<RichTextCustomStyle> customStyles;

  /// Optional callback that maps custom style keys to concrete text styles.
  final RichTextCustomStyleResolver? customStyleResolver;

  /// Base text style for rendering.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Text direction override for this widget.
  final TextDirection? textDirection;

  /// Maximum number of lines for the rendered text.
  final int? maxLines;

  /// Minimum number of lines for the rendered text.
  final int? minLines;

  /// Text scaling configuration.
  final TextScaler? textScaler;

  /// Strut style used for line height and vertical metrics.
  final StrutStyle? strutStyle;

  /// Focus node used by the underlying selectable text widget.
  final FocusNode? focusNode;

  /// Whether this widget should request focus when first built.
  final bool autofocus;

  /// Controls how list markers are displayed.
  final RichTextListRenderMode listRenderMode;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final resolved = _resolveFormatResult(encoded, formatResult, codec);
    final span = _buildRichStyledTextSpan(
      result: resolved,
      baseStyle: effectiveStyle,
      customStyles: customStyles,
      customStyleResolver: customStyleResolver,
      listRenderMode: listRenderMode,
    );

    return SelectableText.rich(
      span,
      style: effectiveStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      maxLines: maxLines,
      minLines: minLines,
      textScaler: textScaler,
      strutStyle: strutStyle,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

RichTextFormatResult _resolveFormatResult(
  String? encoded,
  RichTextFormatResult? formatResult,
  RichTextCodec codec,
) {
  if (formatResult != null) {
    return formatResult;
  }
  return codec.decode(encoded ?? '');
}

TextSpan _buildRichStyledTextSpan({
  required RichTextFormatResult result,
  required TextStyle baseStyle,
  required Iterable<RichTextCustomStyle> customStyles,
  required RichTextListRenderMode listRenderMode,
  RichTextCustomStyleResolver? customStyleResolver,
}) {
  final styleBuilders = _collectCustomStyleBuilders(customStyles);
  final displayText = _renderListMarkers(result.text, listRenderMode);

  if (displayText.isEmpty) {
    return TextSpan(style: baseStyle, text: displayText);
  }

  final boundaries = _collectReadOnlyBoundaries(result, 0, result.text.length);
  final children = <TextSpan>[];

  for (var i = 0; i < boundaries.length - 1; i += 1) {
    final start = boundaries[i];
    final end = boundaries[i + 1];
    if (start == end) {
      continue;
    }
    final segmentStyle = _buildReadOnlySegmentStyle(
      result,
      baseStyle,
      start,
      end,
      styleBuilders,
      customStyleResolver,
    );
    children.add(
      TextSpan(text: displayText.substring(start, end), style: segmentStyle),
    );
  }

  return TextSpan(style: baseStyle, children: children);
}

Map<String, RichTextStyleBuilder> _collectCustomStyleBuilders(
  Iterable<RichTextCustomStyle> customStyles,
) {
  final builders = <String, RichTextStyleBuilder>{};
  for (final style in customStyles) {
    final builder = style.styleBuilder;
    if (builder == null) {
      continue;
    }
    builders[style.key] = builder;
  }
  return builders;
}

TextStyle _buildReadOnlySegmentStyle(
  RichTextFormatResult result,
  TextStyle base,
  int start,
  int end,
  Map<String, RichTextStyleBuilder> styleBuilders,
  RichTextCustomStyleResolver? customStyleResolver,
) {
  var style = base;
  if (_anyRangeCovers(result.boldRanges, start, end)) {
    style = style.copyWith(fontWeight: FontWeight.bold);
  }
  if (_anyRangeCovers(result.italicRanges, start, end)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  if (_anyRangeCovers(result.underlineRanges, start, end)) {
    style = style.copyWith(decoration: _appendUnderline(style.decoration));
  }
  final color = _colorForRange(result.colorRanges, start, end);
  if (color != null) {
    style = style.copyWith(color: color);
  }

  for (final entry in result.customStyleRanges.entries) {
    if (!_anyRangeCovers(entry.value, start, end)) {
      continue;
    }
    final resolved = customStyleResolver?.call(entry.key, style);
    if (resolved != null) {
      style = resolved;
      continue;
    }
    final builder = styleBuilders[entry.key];
    if (builder != null) {
      style = builder(style);
    }
  }

  return style;
}

TextDecoration _appendUnderline(TextDecoration? decoration) {
  if (decoration == null || decoration == TextDecoration.none) {
    return TextDecoration.underline;
  }
  return TextDecoration.combine([decoration, TextDecoration.underline]);
}

String _renderListMarkers(String text, RichTextListRenderMode mode) {
  if (mode == RichTextListRenderMode.literal || text.isEmpty) {
    return text;
  }

  final lines = text.split('\n');
  final rewritten = <String>[];
  for (final line in lines) {
    if (line.startsWith('- ')) {
      rewritten.add('• ${line.substring(2)}');
    } else {
      rewritten.add(line);
    }
  }
  return rewritten.join('\n');
}

List<int> _collectReadOnlyBoundaries(
  RichTextFormatResult result,
  int start,
  int end,
) {
  final boundaries = <int>{start, end};

  void addRange(RichTextRange range) {
    boundaries.add(range.start.clamp(start, end));
    boundaries.add(range.end.clamp(start, end));
  }

  for (final range in result.boldRanges) {
    addRange(range);
  }
  for (final range in result.italicRanges) {
    addRange(range);
  }
  for (final range in result.underlineRanges) {
    addRange(range);
  }
  for (final range in result.colorRanges) {
    addRange(range);
  }
  for (final ranges in result.customStyleRanges.values) {
    for (final range in ranges) {
      addRange(range);
    }
  }

  final sorted = boundaries.toList()..sort();
  return sorted;
}
