import 'package:flutter_test/flutter_test.dart';
import 'package:rich_form_field/rich_form_field.dart';

void main() {
  test('HtmlRichTextCodec decodes styles and lists', () {
    const codec = HtmlRichTextCodec();

    final result = codec.decode(
      '<p><b>Hello</b> <i>world</i></p><ul><li>Item</li></ul>',
    );

    expect(result.text, 'Hello world\n- Item');
    expect(result.boldRanges, hasLength(1));
    expect(result.italicRanges, hasLength(1));
    expect(result.boldRanges.first.start, 0);
    expect(result.boldRanges.first.end, 5);
    expect(result.italicRanges.first.start, 6);
    expect(result.italicRanges.first.end, 11);
  });

  test('HtmlRichTextCodec encodes lists and escapes HTML', () {
    const codec = HtmlRichTextCodec();

    final value = RichTextFormatResult(
      text: '- <tag>\nPlain',
      boldRanges: [],
      italicRanges: [],
      underlineRanges: [],
      colorRanges: [],
    );

    final html = codec.encode(value);

    expect(html, '<ul><li>&lt;tag&gt;</li></ul><p>Plain</p>');
  });

  test('HtmlRichTextCodec supports custom styles by key', () {
    const style = RichTextCustomStyle(
      key: 'highlight',
      tag: 'mark',
      className: 'hl',
    );
    final codec = HtmlRichTextCodec(customStyles: const [style]);

    final result = codec.decode('<p><mark class="hl">Hi</mark></p>');

    expect(result.customStyleRanges['highlight'], isNotNull);
    expect(result.customStyleRanges['highlight']!.first.start, 0);
    expect(result.customStyleRanges['highlight']!.first.end, 2);

    final html = codec.encode(
      RichTextFormatResult(
        text: 'Hi',
        boldRanges: [],
        italicRanges: [],
        underlineRanges: [],
        colorRanges: [],
        customStyleRanges: {
          'highlight': [RichTextRange(0, 2)],
        },
      ),
    );

    expect(
      html,
      '<p><mark data-rff-style="highlight" class="hl">Hi</mark></p>',
    );
  });
}
