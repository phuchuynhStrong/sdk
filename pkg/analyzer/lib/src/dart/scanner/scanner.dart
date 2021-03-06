// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/scanner.dart' as fasta;
import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;
import 'package:front_end/src/scanner/token.dart' show Token, TokenType;
import 'package:pub_semver/pub_semver.dart';

export 'package:analyzer/src/dart/error/syntactic_errors.dart';

/**
 * The class `Scanner` implements a scanner for Dart code.
 *
 * The lexical structure of Dart is ambiguous without knowledge of the context
 * in which a token is being scanned. For example, without context we cannot
 * determine whether source of the form "<<" should be scanned as a single
 * left-shift operator or as two left angle brackets. This scanner does not have
 * any context, so it always resolves such conflicts by scanning the longest
 * possible token.
 */
class Scanner {
  final Source source;

  /**
   * The text to be scanned.
   */
  final String _contents;

  /**
   * The offset of the first character from the reader.
   */
  final int _readerOffset;

  /**
   * The error listener that will be informed of any errors that are found
   * during the scan.
   */
  final AnalysisErrorListener _errorListener;

  /**
   * The flag specifying whether documentation comments should be parsed.
   */
  bool _preserveComments = true;

  final List<int> lineStarts = <int>[];

  Token firstToken;

  /**
   * A flag indicating whether the scanner should recognize the `>>>` operator
   * and the `>>>=` operator.
   *
   * Use [configureFeatures] rather than this field.
   */
  bool enableGtGtGt = false;

  /**
   * A flag indicating whether the scanner should recognize the `late` and
   * `required` keywords.
   *
   * Use [configureFeatures] rather than this field.
   */
  bool enableNonNullable = false;

  FeatureSet _featureSet;

  /**
   * Initialize a newly created scanner to scan characters from the given
   * [source]. The given character [reader] will be used to read the characters
   * in the source. The given [_errorListener] will be informed of any errors
   * that are found.
   */
  factory Scanner(Source source, CharacterReader reader,
          AnalysisErrorListener errorListener) =>
      new Scanner.fasta(source, errorListener,
          contents: reader.getContents(), offset: reader.offset);

  factory Scanner.fasta(Source source, AnalysisErrorListener errorListener,
      {String contents, int offset: -1}) {
    return new Scanner._(
        source, contents ?? source.contents.data, offset, errorListener);
  }

  Scanner._(
      this.source, this._contents, this._readerOffset, this._errorListener) {
    lineStarts.add(0);
  }

  /**
   * The features associated with this scanner.
   *
   * If a language version comment (e.g. '// @dart = 2.3') is detected
   * when calling [tokenize] and this field is non-null, then this field
   * will be updated to contain a downgraded feature set based upon the
   * language version specified.
   *
   * Use [configureFeatures] to set the features.
   */
  FeatureSet get featureSet => _featureSet;

  set preserveComments(bool preserveComments) {
    this._preserveComments = preserveComments;
  }

  /// Configures the scanner appropriately for the given [featureSet].
  ///
  /// TODO(paulberry): stop exposing `enableGtGtGt` and `enableNonNullable` so
  /// that callers are forced to use this API.  Note that this would be a
  /// breaking change.
  void configureFeatures(FeatureSet featureSet) {
    this._featureSet = featureSet;
    enableGtGtGt = featureSet.isEnabled(Feature.triple_shift);
    enableNonNullable = featureSet.isEnabled(Feature.non_nullable);
  }

  void reportError(
      ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    _errorListener
        .onError(new AnalysisError(source, offset, 1, errorCode, arguments));
  }

  void setSourceStart(int line, int column) {
    int offset = _readerOffset;
    if (line < 1 || column < 1 || offset < 0 || (line + column - 2) >= offset) {
      return;
    }
    lineStarts.removeAt(0);
    for (int i = 2; i < line; i++) {
      lineStarts.add(1);
    }
    lineStarts.add(offset - column + 1);
  }

  Token tokenize() {
    fasta.ScannerResult result = fasta.scanString(_contents,
        configuration: _featureSet != null
            ? buildConfig(_featureSet)
            : fasta.ScannerConfiguration(
                enableTripleShift: enableGtGtGt,
                enableNonNullable: enableNonNullable),
        includeComments: _preserveComments,
        languageVersionChanged: _languageVersionChanged);

    // fasta pretends there is an additional line at EOF
    result.lineStarts.removeLast();

    // for compatibility, there is already a first entry in lineStarts
    result.lineStarts.removeAt(0);

    lineStarts.addAll(result.lineStarts);
    fasta.Token token = result.tokens;
    // The default recovery strategy used by scanString
    // places all error tokens at the head of the stream.
    while (token.type == TokenType.BAD_INPUT) {
      translateErrorToken(token, reportError);
      token = token.next;
    }
    firstToken = token;
    // Update all token offsets based upon the reader's starting offset
    if (_readerOffset != -1) {
      final int delta = _readerOffset + 1;
      do {
        token.offset += delta;
        token = token.next;
      } while (!token.isEof);
    }
    return firstToken;
  }

  void _languageVersionChanged(
      fasta.Scanner scanner, fasta.LanguageVersionToken languageVersion) {
    if (_featureSet != null) {
      _featureSet = _featureSet.restrictToVersion(
          Version(languageVersion.major, languageVersion.minor, 0));
      scanner.configuration = buildConfig(_featureSet);
    }
  }

  /// Return a ScannerConfiguration based upon the specified feature set.
  static fasta.ScannerConfiguration buildConfig(FeatureSet featureSet) =>
      featureSet == null
          ? fasta.ScannerConfiguration()
          : fasta.ScannerConfiguration(
              enableTripleShift: featureSet.isEnabled(Feature.triple_shift),
              enableNonNullable: featureSet.isEnabled(Feature.non_nullable));
}
