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

## Features

- `HtmlRichTextFormField` with bold, italic, underline, list, and color tools.
- `HtmlRichTextController` that tracks style ranges and produces HTML output.
- Pluggable `RichTextCodec` for alternative save formats.
- HTML parsing backed by `package:html` and a simple tag subset.

## Getting started

Add the dependency to `pubspec.yaml`:

```yaml
dependencies:
	rich_form_field: ^0.1.0
```

## Usage

```dart
HtmlRichTextFormField(
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

See the full example app in [example/lib/main.dart](example/lib/main.dart).

## Additional information

- Repository: https://github.com/Asion001/rich_form_field
- Issues: https://github.com/Asion001/rich_form_field/issues
