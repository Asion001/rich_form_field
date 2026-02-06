part of 'package:rich_form_field/rich_form_field.dart';

abstract class RichTextCodec {
  const RichTextCodec();

  RichTextFormatResult decode(String input);
  String encode(RichTextFormatResult value);
}

class RichTextRange {
  RichTextRange(this.start, this.end);

  int start;
  int end;
}

class RichTextColorRange extends RichTextRange {
  RichTextColorRange(super.start, super.end, this.color);

  final Color color;
}

class RichTextFormatResult {
  RichTextFormatResult({
    required this.text,
    required this.boldRanges,
    required this.italicRanges,
    required this.underlineRanges,
    required this.colorRanges,
  });

  final String text;
  final List<RichTextRange> boldRanges;
  final List<RichTextRange> italicRanges;
  final List<RichTextRange> underlineRanges;
  final List<RichTextColorRange> colorRanges;
}

class HtmlRichTextCodec extends RichTextCodec {
  const HtmlRichTextCodec();

  @override
  RichTextFormatResult decode(String input) {
    final boldRanges = <RichTextRange>[];
    final italicRanges = <RichTextRange>[];
    final underlineRanges = <RichTextRange>[];
    final colorRanges = <RichTextColorRange>[];

    var boldDepth = 0;
    var italicDepth = 0;
    var underlineDepth = 0;
    final colorStack = <Color?>[];

    final buffer = StringBuffer();

    void appendRaw(String text) {
      if (text.isEmpty) {
        return;
      }
      buffer.write(text);
    }

    void appendText(String text) {
      if (text.isEmpty) {
        return;
      }
      final normalized = text.replaceAll('\u00A0', ' ');
      final start = buffer.length;
      buffer.write(normalized);
      final end = buffer.length;
      if (boldDepth > 0) {
        boldRanges.add(RichTextRange(start, end));
      }
      if (italicDepth > 0) {
        italicRanges.add(RichTextRange(start, end));
      }
      if (underlineDepth > 0) {
        underlineRanges.add(RichTextRange(start, end));
      }
      final currentColor = _currentColor(colorStack);
      if (currentColor != null) {
        colorRanges.add(RichTextColorRange(start, end, currentColor));
      }
    }

    void visitNode(html_dom.Node node) {
      if (node is html_dom.Text) {
        appendText(node.data);
        return;
      }
      if (node is! html_dom.Element) {
        return;
      }

      final name = node.localName?.toLowerCase() ?? '';
      switch (name) {
        case 'br':
          appendRaw('\n');
          return;
        case 'li':
          if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
            appendRaw('\n');
          }
          appendRaw('- ');
          for (final child in node.nodes) {
            visitNode(child);
          }
          if (!buffer.toString().endsWith('\n')) {
            appendRaw('\n');
          }
          return;
        case 'p':
        case 'div':
          if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
            appendRaw('\n');
          }
          for (final child in node.nodes) {
            visitNode(child);
          }
          if (!buffer.toString().endsWith('\n')) {
            appendRaw('\n');
          }
          return;
      }

      final isBold = name == 'b' || name == 'strong';
      final isItalic = name == 'i' || name == 'em';
      final isUnderline = name == 'u' || name == 'ins';
      final isSpan = name == 'span';

      if (isBold) {
        boldDepth += 1;
      }
      if (isItalic) {
        italicDepth += 1;
      }
      if (isUnderline) {
        underlineDepth += 1;
      }
      if (isSpan) {
        colorStack.add(_parseColorFromStyle(node.attributes['style']));
      }

      for (final child in node.nodes) {
        visitNode(child);
      }

      if (isSpan && colorStack.isNotEmpty) {
        colorStack.removeLast();
      }
      if (isUnderline && underlineDepth > 0) {
        underlineDepth -= 1;
      }
      if (isItalic && italicDepth > 0) {
        italicDepth -= 1;
      }
      if (isBold && boldDepth > 0) {
        boldDepth -= 1;
      }
    }

    final fragment = html_parser.parseFragment(input);
    for (final node in fragment.nodes) {
      visitNode(node);
    }

    var text = buffer.toString();
    text = _trimTrailingNewlines(text);

    return RichTextFormatResult(
      text: text,
      boldRanges: boldRanges,
      italicRanges: italicRanges,
      underlineRanges: underlineRanges,
      colorRanges: colorRanges,
    );
  }

  @override
  String encode(RichTextFormatResult value) {
    final lines = _splitLines(value.text);
    final buffer = StringBuffer();
    var inList = false;
    var offset = 0;

    for (final line in lines) {
      final lineStart = offset;
      final lineEnd = lineStart + line.length;
      offset = lineEnd + 1;

      final isList = line.startsWith('- ');
      final contentStart = isList ? lineStart + 2 : lineStart;
      final contentEnd = lineEnd;
      final lineHtml = _buildHtmlForRange(value, contentStart, contentEnd);

      if (isList) {
        if (!inList) {
          buffer.write('<ul>');
          inList = true;
        }
        buffer.write('<li>$lineHtml</li>');
      } else {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        if (lineHtml.isEmpty) {
          buffer.write('<br>');
        } else {
          buffer.write('<p>$lineHtml</p>');
        }
      }
    }

    if (inList) {
      buffer.write('</ul>');
    }

    return buffer.toString();
  }
}

String _buildHtmlForRange(RichTextFormatResult value, int start, int end) {
  if (start >= end) {
    return '';
  }

  final boundaries = _collectBoundariesFromRanges(value, start, end);
  final buffer = StringBuffer();

  for (var i = 0; i < boundaries.length - 1; i += 1) {
    final segStart = boundaries[i];
    final segEnd = boundaries[i + 1];
    if (segStart == segEnd) {
      continue;
    }

    final segment = value.text.substring(segStart, segEnd);
    buffer.write(_wrapHtmlSegment(value, segment, segStart, segEnd));
  }

  return buffer.toString();
}

List<int> _collectBoundariesFromRanges(
  RichTextFormatResult value,
  int start,
  int end,
) {
  final boundaries = <int>{start, end};

  void addRange(RichTextRange range) {
    boundaries.add(range.start.clamp(start, end));
    boundaries.add(range.end.clamp(start, end));
  }

  for (final range in value.boldRanges) {
    addRange(range);
  }
  for (final range in value.italicRanges) {
    addRange(range);
  }
  for (final range in value.underlineRanges) {
    addRange(range);
  }
  for (final range in value.colorRanges) {
    addRange(range);
  }

  final sorted = boundaries.toList()..sort();
  return sorted;
}

String _wrapHtmlSegment(
  RichTextFormatResult value,
  String text,
  int start,
  int end,
) {
  var result = _escapeHtml(text);
  final color = _colorForRange(value.colorRanges, start, end);
  if (color != null) {
    result = '<span style="color: ${_colorToHex(color)}">$result</span>';
  }
  if (_anyRangeCovers(value.underlineRanges, start, end)) {
    result = '<u>$result</u>';
  }
  if (_anyRangeCovers(value.italicRanges, start, end)) {
    result = '<i>$result</i>';
  }
  if (_anyRangeCovers(value.boldRanges, start, end)) {
    result = '<b>$result</b>';
  }
  return result;
}

bool _anyRangeCovers(List<RichTextRange> ranges, int start, int end) {
  return ranges.any((range) => range.start <= start && range.end >= end);
}

Color? _colorForRange(List<RichTextColorRange> ranges, int start, int end) {
  for (final range in ranges) {
    if (range.start <= start && range.end >= end) {
      return range.color;
    }
  }
  return null;
}
