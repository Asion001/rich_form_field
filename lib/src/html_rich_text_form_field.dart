part of 'package:rich_form_field/rich_form_field.dart';

/// Builds a fully custom toolbar for the rich text field.
typedef HtmlRichTextToolbarBuilder =
    Widget Function(BuildContext context, HtmlRichTextController controller);

/// Presents a custom color picker and returns the selected color.
typedef RichTextColorPicker =
    Future<Color?> Function(BuildContext context, Color? currentColor);

/// Available tools for the default toolbar.
enum DefaultTool { bold, italic, underline, list, color }

/// Declares a custom tool button for the default toolbar.
class RichTextCustomTool {
  const RichTextCustomTool({
    required this.id,
    required this.iconBuilder,
    required this.tooltip,
    required this.onPressed,
    this.isActive,
    this.isEnabled,
  });

  final String id;
  final Widget Function(BuildContext context, bool isActive) iconBuilder;
  final String tooltip;
  final ValueChanged<HtmlRichTextController> onPressed;
  final bool Function(HtmlRichTextController controller)? isActive;
  final bool Function(HtmlRichTextController controller)? isEnabled;
}

class HtmlRichTextFormField extends StatefulWidget {
  const HtmlRichTextFormField({
    super.key,
    required this.strings,
    this.controller,
    this.initialHtml,
    this.codec,
    this.customStyles = const [],
    this.focusNode,
    this.decoration,
    this.enabled = true,
    this.autoInsertListMarkers = false,
    this.readOnly = false,
    this.minLines = 4,
    this.maxLines = 8,
    this.style,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.autovalidateMode,
    this.colorPalette,
    this.onPickColor,
    this.toolbarTools,
    this.customTools = const [],
    this.toolbarBuilder,
  });

  final RichTextEditorStrings strings;
  final HtmlRichTextController? controller;
  final String? initialHtml;
  final RichTextCodec? codec;
  final List<RichTextCustomStyle> customStyles;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final bool enabled;
  final bool readOnly;
  final int minLines;
  final int maxLines;
  final TextStyle? style;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final AutovalidateMode? autovalidateMode;
  final List<Color>? colorPalette;
  final RichTextColorPicker? onPickColor;
  final List<DefaultTool>? toolbarTools;
  final List<RichTextCustomTool> customTools;
  final HtmlRichTextToolbarBuilder? toolbarBuilder;
  final bool autoInsertListMarkers;

  @override
  State<HtmlRichTextFormField> createState() => _HtmlRichTextFormFieldState();
}

class _HtmlRichTextFormFieldState extends State<HtmlRichTextFormField> {
  final _formKey = GlobalKey<FormFieldState<String>>();
  late HtmlRichTextController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(HtmlRichTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _disposeController();
      _initController();
    } else if (widget.controller == null && oldWidget.codec != widget.codec) {
      _disposeController();
      _initController();
    } else if (widget.controller == null &&
        oldWidget.initialHtml != widget.initialHtml) {
      _controller.setEncoded(widget.initialHtml ?? '');
      _notifyFormField();
    } else if (oldWidget.customStyles != widget.customStyles) {
      _controller.registerStyles(widget.customStyles);
    }

    if (oldWidget.autoInsertListMarkers != widget.autoInsertListMarkers) {
      _controller.autoInsertListMarkers = widget.autoInsertListMarkers;
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = HtmlRichTextController(
        html: widget.initialHtml ?? '',
        codec: widget.codec ?? _buildCodec(),
        customStyles: widget.customStyles,
        autoInsertListMarkers: widget.autoInsertListMarkers,
      );
      _ownsController = true;
    }
    if (!_ownsController) {
      _controller.registerStyles(widget.customStyles);
      _controller.autoInsertListMarkers = widget.autoInsertListMarkers;
    }
    _controller.addListener(_handleControllerChanged);
  }

  RichTextCodec _buildCodec() {
    if (widget.customStyles.isEmpty) {
      return const HtmlRichTextCodec();
    }
    return HtmlRichTextCodec(customStyles: widget.customStyles);
  }

  void _disposeController() {
    if (_ownsController) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleControllerChanged);
    }
  }

  void _handleControllerChanged() {
    _notifyFormField();
    widget.onChanged?.call(_controller.encoded);
  }

  void _notifyFormField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _formKey.currentState?.didChange(_controller.encoded);
    });
  }

  Future<void> _pickColor() async {
    if (widget.readOnly || !widget.enabled) {
      return;
    }

    final selected = await (widget.onPickColor ?? _defaultPickColor)(
      context,
      _controller.activeColor,
    );

    if (!mounted) {
      return;
    }

    _controller.applyColor(selected);
  }

  Future<Color?> _defaultPickColor(BuildContext context, Color? currentColor) {
    final palette = widget.colorPalette ?? _defaultPalette;
    return showDialog<Color?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.strings.textColor),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in palette)
                  _ColorChip(
                    color: color,
                    onTap: () => Navigator.of(context).pop(color),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(widget.strings.clear),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.strings.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = (widget.decoration ?? const InputDecoration())
        .applyDefaults(theme.inputDecorationTheme);

    return FormField<String>(
      key: _formKey,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      initialValue: _controller.encoded,
      enabled: widget.enabled,
      builder: (state) {
        final effectiveDecoration = decoration.copyWith(
          errorText: state.errorText,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final toolbarBuilder = widget.toolbarBuilder;
                if (toolbarBuilder != null) {
                  return toolbarBuilder(context, _controller);
                }

                final tools = widget.toolbarTools ?? _defaultToolbarTools;
                return _Toolbar(
                  controller: _controller,
                  tools: tools,
                  customTools: widget.customTools,
                  onPickColor: _pickColor,
                  strings: widget.strings,
                );
              },
            ),
            TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              style: widget.style ?? theme.textTheme.bodyMedium,
              decoration: effectiveDecoration,
            ),
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.tools,
    required this.customTools,
    required this.onPickColor,
    required this.strings,
  });

  final HtmlRichTextController controller;
  final List<DefaultTool> tools;
  final List<RichTextCustomTool> customTools;
  final Future<void> Function() onPickColor;
  final RichTextEditorStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = controller.activeColor ?? Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: Wrap(
        spacing: 8,
        children: [
          for (final tool in tools) _buildDefaultTool(context, tool, color),
          for (final tool in customTools) _buildCustomTool(context, tool),
        ],
      ),
    );
  }

  Widget _buildDefaultTool(
    BuildContext context,
    DefaultTool tool,
    Color activeColor,
  ) {
    switch (tool) {
      case DefaultTool.bold:
        return _ToggleIconButton(
          icon: Icons.format_bold,
          tooltip: strings.bold,
          selected: controller.isBoldActive,
          onPressed: controller.toggleBold,
        );
      case DefaultTool.italic:
        return _ToggleIconButton(
          icon: Icons.format_italic,
          tooltip: strings.italic,
          selected: controller.isItalicActive,
          onPressed: controller.toggleItalic,
        );
      case DefaultTool.underline:
        return _ToggleIconButton(
          icon: Icons.format_underline,
          tooltip: strings.underline,
          selected: controller.isUnderlineActive,
          onPressed: controller.toggleUnderline,
        );
      case DefaultTool.list:
        return _ToggleIconButton(
          icon: Icons.format_list_bulleted,
          tooltip: strings.list,
          selected: controller.isListActive,
          onPressed: controller.toggleList,
        );
      case DefaultTool.color:
        return IconButton(
          onPressed: onPickColor,
          tooltip: strings.textColor,
          icon: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: activeColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }

  Widget _buildCustomTool(BuildContext context, RichTextCustomTool tool) {
    final enabled = tool.isEnabled?.call(controller) ?? true;
    final selected = tool.isActive?.call(controller) ?? false;
    return IconButton(
      onPressed: enabled ? () => tool.onPressed(controller) : null,
      tooltip: tool.tooltip,
      icon: tool.iconBuilder(context, selected),
    );
  }
}

class _ToggleIconButton extends StatelessWidget {
  const _ToggleIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : null;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: color),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}

const List<Color> _defaultPalette = [
  Color(0xFF000000),
  Color(0xFF424242),
  Color(0xFF616161),
  Color(0xFF9E9E9E),
  Color(0xFFBDBDBD),
  Color(0xFFEF5350),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF7E57C2),
  Color(0xFF5C6BC0),
  Color(0xFF42A5F5),
  Color(0xFF26C6DA),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFFFFEE58),
  Color(0xFFFFCA28),
  Color(0xFFFFA726),
  Color(0xFF8D6E63),
];

const List<DefaultTool> _defaultToolbarTools = [
  DefaultTool.bold,
  DefaultTool.italic,
  DefaultTool.underline,
  DefaultTool.list,
  DefaultTool.color,
];
