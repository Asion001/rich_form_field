part of 'package:rich_form_field/rich_form_field.dart';

class HtmlRichTextFormField extends StatefulWidget {
  const HtmlRichTextFormField({
    super.key,
    required this.strings,
    this.controller,
    this.initialHtml,
    this.focusNode,
    this.decoration,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 4,
    this.maxLines = 8,
    this.style,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.autovalidateMode,
    this.colorPalette,
  });

  final RichTextEditorStrings strings;
  final HtmlRichTextController? controller;
  final String? initialHtml;
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
    } else if (widget.controller == null &&
        oldWidget.initialHtml != widget.initialHtml) {
      _controller.setHtml(widget.initialHtml ?? '');
      _notifyFormField();
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
      _controller = HtmlRichTextController(html: widget.initialHtml ?? '');
      _ownsController = true;
    }
    _controller.addListener(_handleControllerChanged);
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
    widget.onChanged?.call(_controller.html);
  }

  void _notifyFormField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _formKey.currentState?.didChange(_controller.html);
    });
  }

  Future<void> _pickColor() async {
    if (widget.readOnly || !widget.enabled) {
      return;
    }

    final palette = widget.colorPalette ?? _defaultPalette;
    final selected = await showDialog<Color?>(
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

    if (!mounted) {
      return;
    }

    _controller.applyColor(selected);
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
      initialValue: _controller.html,
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
                return _Toolbar(
                  onBold: _controller.toggleBold,
                  onItalic: _controller.toggleItalic,
                  onUnderline: _controller.toggleUnderline,
                  onList: _controller.toggleList,
                  onColor: _pickColor,
                  isBold: _controller.isBoldActive,
                  isItalic: _controller.isItalicActive,
                  isUnderline: _controller.isUnderlineActive,
                  isList: _controller.isListActive,
                  activeColor: _controller.activeColor,
                  boldLabel: widget.strings.bold,
                  italicLabel: widget.strings.italic,
                  underlineLabel: widget.strings.underline,
                  listLabel: widget.strings.list,
                  colorLabel: widget.strings.textColor,
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
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onList,
    required this.onColor,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.isList,
    required this.activeColor,
    required this.boldLabel,
    required this.italicLabel,
    required this.underlineLabel,
    required this.listLabel,
    required this.colorLabel,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onList;
  final VoidCallback onColor;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isList;
  final Color? activeColor;
  final String boldLabel;
  final String italicLabel;
  final String underlineLabel;
  final String listLabel;
  final String colorLabel;

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: Wrap(
        spacing: 8,
        children: [
          _ToggleIconButton(
            icon: Icons.format_bold,
            tooltip: boldLabel,
            selected: isBold,
            onPressed: onBold,
          ),
          _ToggleIconButton(
            icon: Icons.format_italic,
            tooltip: italicLabel,
            selected: isItalic,
            onPressed: onItalic,
          ),
          _ToggleIconButton(
            icon: Icons.format_underline,
            tooltip: underlineLabel,
            selected: isUnderline,
            onPressed: onUnderline,
          ),
          _ToggleIconButton(
            icon: Icons.format_list_bulleted,
            tooltip: listLabel,
            selected: isList,
            onPressed: onList,
          ),
          IconButton(
            onPressed: onColor,
            tooltip: colorLabel,
            icon: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
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
  final VoidCallback onPressed;

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
