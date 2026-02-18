import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_form_field/rich_form_field.dart';

void main() {
  testWidgets('RichStyledText decodes encoded input with styles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RichStyledText(encoded: '<p><b>Hello</b> <i>world</i></p>'),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    final span = text.textSpan! as TextSpan;
    final children = span.children!;

    expect(children, hasLength(3));
    expect(children[0].toPlainText(), 'Hello');
    expect(children[0].style?.fontWeight, FontWeight.bold);
    expect(children[2].toPlainText(), 'world');
    expect(children[2].style?.fontStyle, FontStyle.italic);
  });

  testWidgets('RichStyledText renders plain text without html tags', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RichStyledText(encoded: 'Just plain text')),
      ),
    );

    expect(find.text('Just plain text'), findsOneWidget);
  });

  testWidgets('RichStyledText supports fromResult and list bullets', (
    tester,
  ) async {
    final result = RichTextFormatResult(
      text: '- Item one\n- Item two',
      boldRanges: const [],
      italicRanges: const [],
      underlineRanges: const [],
      colorRanges: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RichStyledText.fromResult(
            result: result,
            listRenderMode: RichTextListRenderMode.bullets,
          ),
        ),
      ),
    );

    expect(find.text('• Item one\n• Item two'), findsOneWidget);
  });

  testWidgets('RichSelectableStyledText applies custom style resolver', (
    tester,
  ) async {
    final result = RichTextFormatResult(
      text: 'Custom',
      boldRanges: const [],
      italicRanges: const [],
      underlineRanges: const [],
      colorRanges: const [],
      customStyleRanges: {
        'badge': [RichTextRange(0, 6)],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RichSelectableStyledText.fromResult(
            result: result,
            customStyleResolver: _resolver,
          ),
        ),
      ),
    );

    final widget = tester.widget<SelectableText>(find.byType(SelectableText));
    final span = widget.textSpan!;
    final children = span.children!;

    expect(children.single.toPlainText(), 'Custom');
    expect(children.single.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('RichSelectableStyledText supports encoded input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RichSelectableStyledText(encoded: '<p><u>Under</u></p>'),
        ),
      ),
    );

    final widget = tester.widget<SelectableText>(find.byType(SelectableText));
    final span = widget.textSpan!;
    final children = span.children!;

    expect(children.single.toPlainText(), 'Under');
    expect(children.single.style?.decoration, TextDecoration.underline);
  });
}

TextStyle? _resolver(String key, TextStyle base) {
  if (key == 'badge') {
    return base.copyWith(fontWeight: FontWeight.w700);
  }
  return null;
}
