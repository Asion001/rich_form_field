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
  late final HtmlRichTextController _controller;
  String _html = '';

  @override
  void initState() {
    super.initState();
    _controller = HtmlRichTextController(
      html: '<p>Hello <b>rich</b> field.</p>',
    );
    _html = _controller.encoded;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rich Form Field Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HtmlRichTextFormField(
              controller: _controller,
              strings: const RichTextEditorStrings(
                bold: 'Bold',
                italic: 'Italic',
                underline: 'Underline',
                list: 'List',
                textColor: 'Color',
                clear: 'Clear',
                cancel: 'Cancel',
              ),
              onChanged: (value) {
                setState(() {
                  _html = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Current HTML:'),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _html.isEmpty ? '(empty)' : _html,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
