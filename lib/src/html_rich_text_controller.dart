part of 'package:rich_form_field/rich_form_field.dart';

class HtmlRichTextController extends TextEditingController {
  HtmlRichTextController({String? html}) {
    setHtml(html ?? '');
    _lastText = text;
    addListener(_handleChange);
  }

  final List<_Range> _boldRanges = [];
  final List<_Range> _italicRanges = [];
  final List<_Range> _underlineRanges = [];
  final List<_ColorRange> _colorRanges = [];

  bool _pendingBold = false;
  bool _pendingItalic = false;
  bool _pendingUnderline = false;
  Color? _pendingColor;

  String _lastText = '';
  bool _suppressChanges = false;

  String get html => _buildHtml();

  bool get isBoldActive => _selectionHasStyle(_boldRanges) || _pendingBold;
  bool get isItalicActive =>
      _selectionHasStyle(_italicRanges) || _pendingItalic;
  bool get isUnderlineActive =>
      _selectionHasStyle(_underlineRanges) || _pendingUnderline;
  bool get isListActive => _selectionHasList();

  Color? get activeColor => _selectionColor() ?? _pendingColor;

  void setHtml(String html) {
    final result = _HtmlParser.parse(html);
    _suppressChanges = true;
    _boldRanges
      ..clear()
      ..addAll(result.boldRanges);
    _italicRanges
      ..clear()
      ..addAll(result.italicRanges);
    _underlineRanges
      ..clear()
      ..addAll(result.underlineRanges);
    _colorRanges
      ..clear()
      ..addAll(result.colorRanges);
    value = value.copyWith(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.text.length),
      composing: TextRange.empty,
    );
    _pendingBold = false;
    _pendingItalic = false;
    _pendingUnderline = false;
    _pendingColor = null;
    _lastText = text;
    _suppressChanges = false;
  }

  void toggleBold() =>
      _toggleStyle(_boldRanges, (value) => _pendingBold = value);

  void toggleItalic() =>
      _toggleStyle(_italicRanges, (value) => _pendingItalic = value);

  void toggleUnderline() =>
      _toggleStyle(_underlineRanges, (value) => _pendingUnderline = value);

  void applyColor(Color? color) {
    final selection = this.selection;
    if (!selection.isValid) {
      return;
    }

    if (selection.isCollapsed) {
      _pendingColor = color;
      notifyListeners();
      return;
    }

    _colorRanges
      ..removeWhere((range) => range.overlaps(selection.start, selection.end))
      ..addAll(
        color == null
            ? []
            : [_ColorRange(selection.start, selection.end, color)],
      );
    _normalizeColorRanges();
    notifyListeners();
  }

  void toggleList() {
    final selection = this.selection;
    if (!selection.isValid) {
      return;
    }

    final result = _toggleListMarkers(text, selection);
    _applyTextChange(result.text, result.selection);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: text);
    }

    final boundaries = _collectBoundaries(0, text.length);
    final children = <TextSpan>[];

    for (var i = 0; i < boundaries.length - 1; i += 1) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      if (start == end) {
        continue;
      }

      final segment = text.substring(start, end);
      final segmentStyle = _buildSegmentStyle(baseStyle, start, end);
      children.add(TextSpan(text: segment, style: segmentStyle));
    }

    return TextSpan(style: baseStyle, children: children);
  }

  void _handleChange() {
    if (_suppressChanges) {
      return;
    }

    final newText = text;
    final oldText = _lastText;
    if (newText == oldText) {
      return;
    }

    final diff = _TextDiff.compute(oldText, newText);
    _shiftRanges(diff);

    if (diff.insertedLength > 0) {
      _applyPendingStyles(diff.newStart, diff.newStart + diff.insertedLength);
      if (_shouldInsertListMarker(diff, newText)) {
        _insertListMarker();
        return;
      }
    }

    _lastText = newText;
  }

  void _shiftRanges(_TextDiff diff) {
    _shiftRangeList(_boldRanges, diff);
    _shiftRangeList(_italicRanges, diff);
    _shiftRangeList(_underlineRanges, diff);
    _shiftColorRanges(diff);
  }

  void _shiftRangeList(List<_Range> ranges, _TextDiff diff) {
    final updated = <_Range>[];
    for (final range in ranges) {
      updated.addAll(range.shifted(diff));
    }
    ranges
      ..clear()
      ..addAll(updated);
  }

  void _shiftColorRanges(_TextDiff diff) {
    final updated = <_ColorRange>[];
    for (final range in _colorRanges) {
      updated.addAll(range.shifted(diff));
    }
    _colorRanges
      ..clear()
      ..addAll(updated);
  }

  void _applyPendingStyles(int start, int end) {
    if (start >= end) {
      return;
    }

    if (_pendingBold) {
      _boldRanges.add(_Range(start, end));
    }
    if (_pendingItalic) {
      _italicRanges.add(_Range(start, end));
    }
    if (_pendingUnderline) {
      _underlineRanges.add(_Range(start, end));
    }
    if (_pendingColor != null) {
      _colorRanges.add(_ColorRange(start, end, _pendingColor!));
    }

    _normalizeRanges(_boldRanges);
    _normalizeRanges(_italicRanges);
    _normalizeRanges(_underlineRanges);
    _normalizeColorRanges();
  }

  void _toggleStyle(List<_Range> ranges, ValueChanged<bool> updatePending) {
    final selection = this.selection;
    if (!selection.isValid) {
      return;
    }

    if (selection.isCollapsed) {
      final enabled = !_pendingFor(ranges);
      updatePending(enabled);
      notifyListeners();
      return;
    }

    if (_isRangeFullyCovered(ranges, selection.start, selection.end)) {
      _removeStyleFromSelection(ranges, selection.start, selection.end);
    } else {
      ranges.add(_Range(selection.start, selection.end));
      _normalizeRanges(ranges);
    }

    notifyListeners();
  }

  bool _pendingFor(List<_Range> ranges) {
    if (ranges == _boldRanges) {
      return _pendingBold;
    }
    if (ranges == _italicRanges) {
      return _pendingItalic;
    }
    if (ranges == _underlineRanges) {
      return _pendingUnderline;
    }
    return false;
  }

  void _removeStyleFromSelection(List<_Range> ranges, int start, int end) {
    final updated = <_Range>[];
    for (final range in ranges) {
      updated.addAll(range.subtract(start, end));
    }
    ranges
      ..clear()
      ..addAll(updated);
  }

  bool _selectionHasStyle(List<_Range> ranges) {
    final selection = this.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return false;
    }
    return _isRangeFullyCovered(ranges, selection.start, selection.end);
  }

  bool _selectionHasList() {
    final selection = this.selection;
    if (!selection.isValid) {
      return false;
    }

    final lines = _selectedLines(text, selection);
    if (lines.isEmpty) {
      return false;
    }

    return lines.every(
      (line) =>
          line.start < line.end &&
          text.substring(line.start, line.end).startsWith('- '),
    );
  }

  Color? _selectionColor() {
    final selection = this.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return null;
    }

    final covering = _colorRanges
        .where((range) => range.covers(selection.start, selection.end))
        .toList();
    if (covering.isEmpty) {
      return null;
    }
    final colors = covering.map((range) => range.color).toSet();
    if (colors.length == 1) {
      return colors.first;
    }
    return null;
  }

  TextStyle _buildSegmentStyle(TextStyle base, int start, int end) {
    var style = base;
    if (_anyRangeCovers(_boldRanges, start, end)) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (_anyRangeCovers(_italicRanges, start, end)) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (_anyRangeCovers(_underlineRanges, start, end)) {
      style = style.copyWith(decoration: TextDecoration.underline);
    }
    final color = _colorForRange(start, end);
    if (color != null) {
      style = style.copyWith(color: color);
    }
    return style;
  }

  Color? _colorForRange(int start, int end) {
    for (final range in _colorRanges) {
      if (range.covers(start, end)) {
        return range.color;
      }
    }
    return null;
  }

  List<int> _collectBoundaries(int start, int end) {
    final boundaries = <int>{start, end};
    for (final range in _boldRanges) {
      boundaries.add(range.start.clamp(start, end));
      boundaries.add(range.end.clamp(start, end));
    }
    for (final range in _italicRanges) {
      boundaries.add(range.start.clamp(start, end));
      boundaries.add(range.end.clamp(start, end));
    }
    for (final range in _underlineRanges) {
      boundaries.add(range.start.clamp(start, end));
      boundaries.add(range.end.clamp(start, end));
    }
    for (final range in _colorRanges) {
      boundaries.add(range.start.clamp(start, end));
      boundaries.add(range.end.clamp(start, end));
    }
    final sorted = boundaries.toList()..sort();
    return sorted;
  }

  bool _anyRangeCovers(List<_Range> ranges, int start, int end) {
    return ranges.any((range) => range.covers(start, end));
  }

  bool _isRangeFullyCovered(List<_Range> ranges, int start, int end) {
    if (start >= end) {
      return false;
    }
    final sorted = ranges.toList()..sort((a, b) => a.start.compareTo(b.start));
    var current = start;
    for (final range in sorted) {
      if (range.end <= current) {
        continue;
      }
      if (range.start > current) {
        return false;
      }
      current = range.end;
      if (current >= end) {
        return true;
      }
    }
    return false;
  }

  void _normalizeRanges(List<_Range> ranges) {
    if (ranges.isEmpty) {
      return;
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Range>[ranges.first];
    for (final range in ranges.skip(1)) {
      final last = merged.last;
      if (range.start <= last.end) {
        last.end = last.end > range.end ? last.end : range.end;
      } else {
        merged.add(range);
      }
    }
    ranges
      ..clear()
      ..addAll(merged);
  }

  void _normalizeColorRanges() {
    if (_colorRanges.isEmpty) {
      return;
    }

    _colorRanges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_ColorRange>[_colorRanges.first];
    for (final range in _colorRanges.skip(1)) {
      final last = merged.last;
      if (range.start <= last.end && range.color == last.color) {
        last.end = last.end > range.end ? last.end : range.end;
      } else {
        merged.add(range);
      }
    }
    _colorRanges
      ..clear()
      ..addAll(merged);
  }

  void _applyTextChange(String newText, TextSelection newSelection) {
    _suppressChanges = true;
    value = value.copyWith(
      text: newText,
      selection: newSelection,
      composing: TextRange.empty,
    );
    _suppressChanges = false;
    _handleChange();
    notifyListeners();
  }

  bool _shouldInsertListMarker(_TextDiff diff, String newText) {
    if (!selection.isValid || !selection.isCollapsed) {
      return false;
    }

    final inserted = newText.substring(diff.newStart, diff.newEnd);
    if (!inserted.endsWith('\n')) {
      return false;
    }

    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > newText.length) {
      return false;
    }

    final lineStart = _lineStartForIndex(newText, diff.newStart);
    if (lineStart + 2 > newText.length) {
      return false;
    }

    if (!newText.substring(lineStart, lineStart + 2).startsWith('- ')) {
      return false;
    }

    if (cursor + 2 <= newText.length &&
        newText.substring(cursor, cursor + 2) == '- ') {
      return false;
    }

    return true;
  }

  void _insertListMarker() {
    final cursor = selection.baseOffset;
    final newText = '${text.substring(0, cursor)}- ${text.substring(cursor)}';
    _applyTextChange(newText, TextSelection.collapsed(offset: cursor + 2));
  }

  String _buildHtml() {
    final lines = _splitLines(text);
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
      final lineHtml = _buildHtmlForRange(contentStart, contentEnd);

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

  String _buildHtmlForRange(int start, int end) {
    if (start >= end) {
      return '';
    }

    final boundaries = _collectBoundaries(start, end);
    final buffer = StringBuffer();

    for (var i = 0; i < boundaries.length - 1; i += 1) {
      final segStart = boundaries[i];
      final segEnd = boundaries[i + 1];
      if (segStart == segEnd) {
        continue;
      }

      final segment = text.substring(segStart, segEnd);
      buffer.write(_wrapHtmlSegment(segment, segStart, segEnd));
    }

    return buffer.toString();
  }

  String _wrapHtmlSegment(String text, int start, int end) {
    var result = _escapeHtml(text);
    final color = _colorForRange(start, end);
    if (color != null) {
      result = '<span style="color: ${_colorToHex(color)}">$result</span>';
    }
    if (_anyRangeCovers(_underlineRanges, start, end)) {
      result = '<u>$result</u>';
    }
    if (_anyRangeCovers(_italicRanges, start, end)) {
      result = '<i>$result</i>';
    }
    if (_anyRangeCovers(_boldRanges, start, end)) {
      result = '<b>$result</b>';
    }
    return result;
  }
}
