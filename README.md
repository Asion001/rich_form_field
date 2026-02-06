<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

Rich text form field with a formatting toolbar, inline style ranges, and
HTML codec output. Designed for simple rich text input in Flutter forms.

![Demo](docs/demo.gif)

## Features

- `HtmlRichTextFormField` with bold, italic, underline, list, and color tools.
- `HtmlRichTextController` that tracks style ranges and produces HTML output.
- Pluggable `RichTextCodec` for alternative save formats.
- Optional auto-insert list markers when pressing Enter.
- HTML parsing backed by `package:html` and a simple tag subset.

## Getting started

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  rich_form_field: ^0.2.0
```

## Usage

```dart
HtmlRichTextFormField(
  autoInsertListMarkers: false,
  strings: const RichTextEditorStrings(
    bold: 'Bold',
    italic: 'Italic',
    underline: 'Underline',
    list: 'List',
    textColor: 'Color',
    clear: 'Clear',
    cancel: 'Cancel',
  ),
  onChanged: (html) {
    // Persist the HTML output.
  },
)
```

### Reading HTML or raw text

```dart
final controller = HtmlRichTextController();

void _submit() {
  final html = controller.encoded;
  final rawText = controller.text;
  // Send html/rawText to your backend.
}

HtmlRichTextFormField(
  controller: controller,
  strings: const RichTextEditorStrings(
    bold: 'Bold',
    italic: 'Italic',
    underline: 'Underline',
    list: 'List',
    textColor: 'Color',
    clear: 'Clear',
    cancel: 'Cancel',
  ),
)
```

### Advanced example

```dart
const customStyles = [
  RichTextCustomStyle(
    key: 'highlight',
    tag: 'mark',
    className: 'highlight',
    styleBuilder: _highlightStyle,
  ),
];

final controller = HtmlRichTextController(
  html: '<p>Hello <b>rich</b> field.</p>',
  codec: HtmlRichTextCodec(customStyles: customStyles),
  customStyles: customStyles,
);

HtmlRichTextFormField(
  controller: controller,
  customStyles: customStyles,
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
        final color = isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color;
        return Icon(Icons.star, color: color);
      },
      tooltip: 'Highlight',
      onPressed: (controller) => controller.toggleCustomStyle('highlight'),
      isActive: (controller) => controller.isCustomStyleActive('highlight'),
    ),
  ],
  onPickColor: (context, currentColor) async {
    return showDialog<Color?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in [Colors.red, Colors.blue, Colors.green])
              InkWell(
                onTap: () => Navigator.of(context).pop(color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
  strings: const RichTextEditorStrings(
    bold: 'Bold',
    italic: 'Italic',
    underline: 'Underline',
    list: 'List',
    textColor: 'Color',
    clear: 'Clear',
    cancel: 'Cancel',
  ),
)

TextStyle _highlightStyle(TextStyle base) {
  return base.copyWith(fontWeight: FontWeight.w600);
}
```

See the full example app in [example/lib/main.dart](example/lib/main.dart).

## Additional information

- Repository: https://github.com/Asion001/rich_form_field
- Issues: https://github.com/Asion001/rich_form_field/issues
