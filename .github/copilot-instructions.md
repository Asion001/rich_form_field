# Copilot Instructions

## Project Overview

- This is a Flutter package that exposes a rich-text form field with HTML output.
- The public entrypoint is a single library file that uses Dart `part` files for implementation.

## Key Files

- lib/rich_form_field.dart: library entrypoint and `part` declarations.
- lib/src/html_rich_text_form_field.dart: UI widget with toolbar + `FormField` integration.
- lib/src/html_rich_text_controller.dart: `TextEditingController` subclass that tracks style ranges and emits HTML.
- lib/src/html_rich_text_helpers.dart: HTML parsing/escaping, range math, list handling utilities.
- lib/src/rich_text_editor_strings.dart: localized labels container.

## Architecture Notes

- `HtmlRichTextController` stores formatting as style ranges, then builds HTML on demand.
- Plain-text list items are represented as lines prefixed with `- `; the controller maps them to `<ul><li>` in HTML.
- HTML parsing/serialization only supports a small tag subset: `b/strong`, `i/em`, `u/ins`, `span` with `color`, `ul/li`, `p/div`, and `br`.

## Conventions and Patterns

- New Dart source files should be added as `part` files under lib/src and wired in lib/rich_form_field.dart.
- `HtmlRichTextFormField` owns an internal controller when none is provided and syncs `FormField` state via listeners.
- HTML escaping/decoding utilities live in lib/src/html_rich_text_helpers.dart and should be reused for any new parsing logic.

## Workflows

- SDK constraints are in pubspec.yaml (Dart >=3.9, Flutter 3.38.9).
- Run tests with `flutter test` (tests live in test/).
- Lints follow package:flutter_lints (see analysis_options.yaml).
