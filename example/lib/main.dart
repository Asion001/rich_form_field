import 'package:flutter/material.dart';
import 'package:rich_form_field/rich_form_field.dart';

void main() {
  runApp(const RichFormFieldExampleApp());
}

class RichFormFieldExampleApp extends StatelessWidget {
  const RichFormFieldExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rich Form Field Example',
      theme: ThemeData(useMaterial3: true),
      home: const RichFormFieldExamplePage(),
    );
  }
}

class RichFormFieldExamplePage extends StatefulWidget {
  const RichFormFieldExamplePage({super.key});

  @override
  State<RichFormFieldExamplePage> createState() =>
      _RichFormFieldExamplePageState();
}

class _RichFormFieldExamplePageState extends State<RichFormFieldExamplePage> {
  late final HtmlRichTextController _simpleController;
  late final HtmlRichTextController _advancedController;
  String _simpleHtml = '';
  String _advancedHtml = '';
  static const _customStyles = [
    RichTextCustomStyle(
      key: 'highlight',
      tag: 'mark',
      className: 'highlight',
      styleBuilder: _highlightStyle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _simpleController = HtmlRichTextController(
      html: '<p>Hello <b>rich</b> field.</p>',
    );
    _simpleHtml = _simpleController.encoded;
    _advancedController = HtmlRichTextController(
      html: '<p>Hello <b>rich</b> field.</p>',
      codec: HtmlRichTextCodec(customStyles: _customStyles),
      customStyles: _customStyles,
    );
    _advancedHtml = _advancedController.encoded;
  }

  @override
  void dispose() {
    _simpleController.dispose();
    _advancedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rich Form Field Example'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Simple'), Tab(text: 'Advanced')],
          ),
        ),
        body: TabBarView(
          children: [
            _ExamplePane(
              controller: _simpleController,
              html: _simpleHtml,
              codec: const HtmlRichTextCodec(),
              onChanged: (value) {
                setState(() {
                  _simpleHtml = value;
                });
              },
            ),
            _ExamplePane(
              controller: _advancedController,
              html: _advancedHtml,
              codec: HtmlRichTextCodec(customStyles: _customStyles),
              customStyles: _customStyles,
              toolbarTools: const [
                DefaultTool.bold,
                DefaultTool.italic,
                DefaultTool.color,
                DefaultTool.list,
                DefaultTool.underline,
              ],
              customTools: [
                RichTextCustomTool(
                  id: 'highlight',
                  iconBuilder: (context, isActive) {
                    final color =
                        isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).iconTheme.color;
                    return Icon(Icons.star, color: color);
                  },
                  tooltip: 'Highlight',
                  onPressed:
                      (controller) => controller.toggleCustomStyle('highlight'),
                  isActive:
                      (controller) =>
                          controller.isCustomStyleActive('highlight'),
                ),
              ],
              onPickColor: _showCustomColorPicker,
              onChanged: (value) {
                setState(() {
                  _advancedHtml = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Color?> _showCustomColorPicker(
    BuildContext context,
    Color? currentColor,
  ) {
    var sliderValue = 128.0;
    return showDialog<Color?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final sliderColor = Color.fromARGB(
              255,
              sliderValue.toInt(),
              64,
              64,
            );
            return AlertDialog(
              title: const Text('Pick a color'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in _accentPalette)
                          _ColorTile(
                            color: color,
                            onTap: () => Navigator.of(context).pop(color),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: sliderValue,
                            max: 255,
                            label: 'Custom',
                            onChanged: (value) {
                              setState(() {
                                sliderValue = value;
                              });
                            },
                          ),
                        ),
                        _ColorTile(
                          color: sliderColor,
                          onTap: () => Navigator.of(context).pop(sliderColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ExamplePane extends StatelessWidget {
  const _ExamplePane({
    required this.controller,
    required this.html,
    required this.codec,
    required this.onChanged,
    this.customStyles = const [],
    this.toolbarTools,
    this.customTools = const [],
    this.onPickColor,
  });

  final HtmlRichTextController controller;
  final String html;
  final RichTextCodec codec;
  final ValueChanged<String> onChanged;
  final List<RichTextCustomStyle> customStyles;
  final List<DefaultTool>? toolbarTools;
  final List<RichTextCustomTool> customTools;
  final RichTextColorPicker? onPickColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HtmlRichTextFormField(
            controller: controller,
            customStyles: customStyles,
            toolbarTools: toolbarTools,
            customTools: customTools,
            onPickColor: onPickColor,
            strings: const RichTextEditorStrings(
              bold: 'Bold',
              italic: 'Italic',
              underline: 'Underline',
              list: 'List',
              textColor: 'Color',
              clear: 'Clear',
              cancel: 'Cancel',
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          const Text('Current HTML:'),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    html.isEmpty ? '(empty)' : html,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  const Text('Styled preview:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RichStyledText(
                      encoded: html.isEmpty ? '(empty)' : html,
                      codec: codec,
                      customStyles: customStyles,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Selectable styled preview:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RichSelectableStyledText(
                      encoded: html.isEmpty ? '(empty)' : html,
                      codec: codec,
                      customStyles: customStyles,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _highlightStyle(TextStyle base) {
  return base.copyWith(
    fontWeight: FontWeight.w600,
    backgroundColor: Colors.amberAccent,
    color: Colors.white,
    fontSize: 18,
  );
}

const _accentPalette = [
  Color(0xFF1E88E5),
  Color(0xFFD32F2F),
  Color(0xFF388E3C),
  Color(0xFFF9A825),
  Color(0xFF6D4C41),
  Color(0xFF5E35B1),
];

class _ColorTile extends StatelessWidget {
  const _ColorTile({required this.color, required this.onTap});

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
