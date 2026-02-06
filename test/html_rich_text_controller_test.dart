import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_form_field/rich_form_field.dart';

void main() {
  test('HtmlRichTextController applies pending bold to new input', () {
    final controller = HtmlRichTextController();

    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.toggleBold();
    controller.value = const TextEditingValue(
      text: 'Hi',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(controller.html, '<p><b>Hi</b></p>');
  });

  test('HtmlRichTextController toggles list markers for selections', () {
    final controller = HtmlRichTextController();

    controller.value = const TextEditingValue(
      text: 'One\nTwo',
      selection: TextSelection(baseOffset: 0, extentOffset: 7),
    );

    controller.toggleList();
    expect(controller.text, '- One\n- Two');

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 11);
    controller.toggleList();
    expect(controller.text, 'One\nTwo');
  });

  test('HtmlRichTextController applies color to a selection', () {
    final controller = HtmlRichTextController();

    controller.value = const TextEditingValue(
      text: 'Hi',
      selection: TextSelection(baseOffset: 0, extentOffset: 2),
    );

    controller.applyColor(Colors.red);

    expect(controller.html, '<p><span style="color: #f44336">Hi</span></p>');
  });

  test('HtmlRichTextController toggles custom styles', () {
    const style = RichTextCustomStyle(
      key: 'badge',
      tag: 'span',
      className: 'badge',
      styleBuilder: _badgeStyleBuilder,
    );
    final codec = HtmlRichTextCodec(customStyles: const [style]);
    final controller = HtmlRichTextController(
      codec: codec,
      customStyles: const [style],
    );

    controller.value = const TextEditingValue(
      text: 'Hi',
      selection: TextSelection(baseOffset: 0, extentOffset: 2),
    );

    controller.toggleCustomStyle('badge');

    expect(
      controller.html,
      '<p><span data-rff-style="badge" class="badge">Hi</span></p>',
    );
    expect(controller.isCustomStyleActive('badge'), isTrue);
  });
}

TextStyle _badgeStyleBuilder(TextStyle base) {
  return base.copyWith(fontWeight: FontWeight.w600);
}
