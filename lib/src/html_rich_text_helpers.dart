part of 'package:rich_form_field/rich_form_field.dart';

class _Range {
  _Range(this.start, this.end);

  int start;
  int end;

  bool covers(int rangeStart, int rangeEnd) {
    return start <= rangeStart && end >= rangeEnd;
  }

  bool overlaps(int rangeStart, int rangeEnd) {
    return start < rangeEnd && end > rangeStart;
  }

  List<_Range> shifted(_TextDiff diff) {
    final list = <_Range>[];
    if (end <= diff.oldStart) {
      list.add(_Range(start, end));
      return list;
    }
    if (start >= diff.oldEnd) {
      list.add(_Range(start + diff.delta, end + diff.delta));
      return list;
    }

    if (start < diff.oldStart) {
      list.add(_Range(start, diff.oldStart));
    }
    if (end > diff.oldEnd) {
      list.add(_Range(diff.oldEnd + diff.delta, end + diff.delta));
    }
    return list;
  }

  List<_Range> subtract(int rangeStart, int rangeEnd) {
    if (!overlaps(rangeStart, rangeEnd)) {
      return [_Range(start, end)];
    }

    final list = <_Range>[];
    if (start < rangeStart) {
      list.add(_Range(start, rangeStart));
    }
    if (end > rangeEnd) {
      list.add(_Range(rangeEnd, end));
    }
    return list;
  }
}

class _ColorRange extends _Range {
  _ColorRange(super.start, super.end, this.color);

  final Color color;

  @override
  List<_ColorRange> shifted(_TextDiff diff) {
    final base = super.shifted(diff);
    return base
        .map((range) => _ColorRange(range.start, range.end, color))
        .toList();
  }

  @override
  List<_ColorRange> subtract(int rangeStart, int rangeEnd) {
    final base = super.subtract(rangeStart, rangeEnd);
    return base
        .map((range) => _ColorRange(range.start, range.end, color))
        .toList();
  }
}

class _TextDiff {
  const _TextDiff({
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
    required this.delta,
  });

  final int oldStart;
  final int oldEnd;
  final int newStart;
  final int newEnd;
  final int delta;

  int get insertedLength => newEnd - newStart;

  static _TextDiff compute(String oldText, String newText) {
    final oldLength = oldText.length;
    final newLength = newText.length;
    final minLength = oldLength < newLength ? oldLength : newLength;

    var prefix = 0;
    while (prefix < minLength && oldText[prefix] == newText[prefix]) {
      prefix += 1;
    }

    var suffix = 0;
    while (suffix < minLength - prefix &&
        oldText[oldLength - 1 - suffix] == newText[newLength - 1 - suffix]) {
      suffix += 1;
    }

    final oldStart = prefix;
    final oldEnd = oldLength - suffix;
    final newStart = prefix;
    final newEnd = newLength - suffix;
    final delta = newLength - oldLength;

    return _TextDiff(
      oldStart: oldStart,
      oldEnd: oldEnd,
      newStart: newStart,
      newEnd: newEnd,
      delta: delta,
    );
  }
}

class _HtmlParseResult {
  _HtmlParseResult({
    required this.text,
    required this.boldRanges,
    required this.italicRanges,
    required this.underlineRanges,
    required this.colorRanges,
  });

  final String text;
  final List<_Range> boldRanges;
  final List<_Range> italicRanges;
  final List<_Range> underlineRanges;
  final List<_ColorRange> colorRanges;
}

class _HtmlParser {
  static _HtmlParseResult parse(String html) {
    final boldRanges = <_Range>[];
    final italicRanges = <_Range>[];
    final underlineRanges = <_Range>[];
    final colorRanges = <_ColorRange>[];

    var boldDepth = 0;
    var italicDepth = 0;
    var underlineDepth = 0;
    final colorStack = <Color?>[];

    final buffer = StringBuffer();

    void appendText(String text) {
      if (text.isEmpty) {
        return;
      }
      final decoded = _decodeEntities(text);
      final start = buffer.length;
      buffer.write(decoded);
      final end = buffer.length;
      if (boldDepth > 0) {
        boldRanges.add(_Range(start, end));
      }
      if (italicDepth > 0) {
        italicRanges.add(_Range(start, end));
      }
      if (underlineDepth > 0) {
        underlineRanges.add(_Range(start, end));
      }
      final currentColor = _currentColor(colorStack);
      if (currentColor != null) {
        colorRanges.add(_ColorRange(start, end, currentColor));
      }
    }

    final tagExp = RegExp(r'<[^>]+>');
    var index = 0;

    while (index < html.length) {
      final matches = tagExp.allMatches(html, index);
      final match = matches.isNotEmpty ? matches.first : null;
      if (match == null) {
        appendText(html.substring(index));
        break;
      }

      if (match.start > index) {
        appendText(html.substring(index, match.start));
      }

      final tag = match.group(0) ?? '';
      _handleTag(
        tag,
        buffer,
        () => boldDepth += 1,
        () => boldDepth = boldDepth > 0 ? boldDepth - 1 : 0,
        () => italicDepth += 1,
        () => italicDepth = italicDepth > 0 ? italicDepth - 1 : 0,
        () => underlineDepth += 1,
        () => underlineDepth = underlineDepth > 0 ? underlineDepth - 1 : 0,
        (color) => colorStack.add(color),
        () {
          if (colorStack.isNotEmpty) {
            colorStack.removeLast();
          }
        },
      );

      index = match.end;
    }

    var text = buffer.toString();
    text = _trimTrailingNewlines(text);

    return _HtmlParseResult(
      text: text,
      boldRanges: boldRanges,
      italicRanges: italicRanges,
      underlineRanges: underlineRanges,
      colorRanges: colorRanges,
    );
  }

  static void _handleTag(
    String tag,
    StringBuffer buffer,
    VoidCallback onBoldStart,
    VoidCallback onBoldEnd,
    VoidCallback onItalicStart,
    VoidCallback onItalicEnd,
    VoidCallback onUnderlineStart,
    VoidCallback onUnderlineEnd,
    ValueChanged<Color?> onColorStart,
    VoidCallback onColorEnd,
  ) {
    final trimmed = tag.toLowerCase().trim();
    final closing = trimmed.startsWith('</');
    final nameMatch = RegExp(r'^</?\s*([a-z0-9]+)').firstMatch(trimmed);
    final name = nameMatch?.group(1) ?? '';

    if (name == 'br') {
      buffer.write('\n');
      return;
    }

    if (name == 'li' && !closing) {
      if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
        buffer.write('\n');
      }
      buffer.write('- ');
      return;
    }

    if (name == 'li' && closing) {
      if (!buffer.toString().endsWith('\n')) {
        buffer.write('\n');
      }
      return;
    }

    if (name == 'p' || name == 'div') {
      if (!closing) {
        if (buffer.isNotEmpty && !buffer.toString().endsWith('\n')) {
          buffer.write('\n');
        }
      } else {
        if (!buffer.toString().endsWith('\n')) {
          buffer.write('\n');
        }
      }
      return;
    }

    if (!closing) {
      switch (name) {
        case 'b':
        case 'strong':
          onBoldStart();
          break;
        case 'i':
        case 'em':
          onItalicStart();
          break;
        case 'u':
        case 'ins':
          onUnderlineStart();
          break;
        case 'span':
          onColorStart(_parseColorFromTag(trimmed));
          break;
      }
    } else {
      switch (name) {
        case 'b':
        case 'strong':
          onBoldEnd();
          break;
        case 'i':
        case 'em':
          onItalicEnd();
          break;
        case 'u':
        case 'ins':
          onUnderlineEnd();
          break;
        case 'span':
          onColorEnd();
          break;
      }
    }
  }
}

class _LineRange {
  _LineRange(this.start, this.end);

  final int start;
  final int end;
}

class _ListToggleResult {
  _ListToggleResult(this.text, this.selection);

  final String text;
  final TextSelection selection;
}

List<_LineRange> _selectedLines(String text, TextSelection selection) {
  if (text.isEmpty) {
    return [];
  }

  final lines = _splitLinesWithIndices(text);
  if (selection.isCollapsed) {
    return lines
        .where(
          (line) =>
              line.start <= selection.start && line.end >= selection.start,
        )
        .toList();
  }

  return lines
      .where((line) => line.start < selection.end && line.end > selection.start)
      .toList();
}

List<String> _splitLines(String text) {
  return text.split('\n');
}

List<_LineRange> _splitLinesWithIndices(String text) {
  final lines = <_LineRange>[];
  var start = 0;
  for (var i = 0; i < text.length; i += 1) {
    if (text[i] == '\n') {
      lines.add(_LineRange(start, i));
      start = i + 1;
    }
  }
  lines.add(_LineRange(start, text.length));
  return lines;
}

int _lineStartForIndex(String text, int index) {
  var start = index.clamp(0, text.length);
  while (start > 0 && text[start - 1] != '\n') {
    start -= 1;
  }
  return start;
}

_ListToggleResult _toggleListMarkers(String text, TextSelection selection) {
  final lines = _selectedLines(text, selection);
  if (lines.isEmpty) {
    return _ListToggleResult(text, selection);
  }

  final shouldAdd = lines.any(
    (line) => !text.substring(line.start, line.end).startsWith('- '),
  );
  final buffer = StringBuffer();
  var deltaBeforeSelectionStart = 0;
  var deltaBeforeSelectionEnd = 0;
  var offset = 0;

  for (var i = 0; i < lines.length; i += 1) {
    final line = lines[i];
    if (offset < line.start) {
      buffer.write(text.substring(offset, line.start));
    }

    var lineText = text.substring(line.start, line.end);
    final originalLength = lineText.length;

    if (shouldAdd) {
      if (!lineText.startsWith('- ')) {
        lineText = '- $lineText';
      }
    } else {
      if (lineText.startsWith('- ')) {
        lineText = lineText.substring(2);
      }
    }

    buffer.write(lineText);
    offset = line.end;

    final delta = lineText.length - originalLength;
    if (line.start < selection.start) {
      deltaBeforeSelectionStart += delta;
    }
    if (line.start < selection.end) {
      deltaBeforeSelectionEnd += delta;
    }
  }

  if (offset < text.length) {
    buffer.write(text.substring(offset));
  }

  final newStart = (selection.start + deltaBeforeSelectionStart).clamp(
    0,
    buffer.length,
  );
  final newEnd = (selection.end + deltaBeforeSelectionEnd).clamp(
    0,
    buffer.length,
  );

  return _ListToggleResult(
    buffer.toString(),
    TextSelection(baseOffset: newStart, extentOffset: newEnd),
  );
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _decodeEntities(String text) {
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

String _trimTrailingNewlines(String text) {
  var trimmed = text;
  while (trimmed.endsWith('\n')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

Color? _parseColorFromTag(String tag) {
  final styleMatch = RegExp(r'style\s*=\s*"([^"]+)"').firstMatch(tag);
  final style = styleMatch?.group(1);
  if (style == null) {
    return null;
  }
  final colorMatch = RegExp(r'color\s*:\s*([^;]+)').firstMatch(style);
  final colorValue = colorMatch?.group(1)?.trim();
  if (colorValue == null) {
    return null;
  }
  return _parseColor(colorValue);
}

Color? _parseColor(String value) {
  final trimmed = value.toLowerCase();
  if (trimmed.startsWith('#')) {
    final hex = trimmed.substring(1);
    if (hex.length == 3) {
      final expanded = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      return Color(int.parse('FF$expanded', radix: 16));
    }
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
  }
  final rgbMatch = RegExp(
    r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
  ).firstMatch(trimmed);
  if (rgbMatch != null) {
    final r = int.parse(rgbMatch.group(1) ?? '0');
    final g = int.parse(rgbMatch.group(2) ?? '0');
    final b = int.parse(rgbMatch.group(3) ?? '0');
    return Color.fromARGB(255, r, g, b);
  }
  return null;
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

Color? _currentColor(List<Color?> stack) {
  for (var i = stack.length - 1; i >= 0; i -= 1) {
    final color = stack[i];
    if (color != null) {
      return color;
    }
  }
  return null;
}
