// Generate hm_icon Dart source from HMSymbolVF.ttf
// Usage: dart run generate_hm_icon.dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

class TTFReader {
  final ByteData _data;
  int _offset = 0;

  TTFReader(this._data);

  int readUint8() => _data.getUint8(_offset++);
  int readUint16() {
    final v = _data.getUint16(_offset, Endian.big);
    _offset += 2;
    return v;
  }

  int readInt16() {
    final v = _data.getInt16(_offset, Endian.big);
    _offset += 2;
    return v;
  }

  int readUint32() {
    final v = _data.getUint32(_offset, Endian.big);
    _offset += 4;
    return v;
  }

  int readInt32() {
    final v = _data.getInt32(_offset, Endian.big);
    _offset += 4;
    return v;
  }

  String readTag() {
    final codes = List.generate(4, (_) => _data.getUint8(_offset++));
    return String.fromCharCodes(codes);
  }

  void seek(int pos) => _offset = pos;
  int tell() => _offset;
}

class TableRecord {
  final String tag;
  final int checkSum;
  final int offset;
  final int length;
  TableRecord(this.tag, this.checkSum, this.offset, this.length);
}

void main() {
  final fontPath = '../fonts/HMSymbolVF.ttf';
  final fontData = File(fontPath).readAsBytesSync();
  final reader = TTFReader(ByteData.view(fontData.buffer));

  // Read offset table
  reader.readUint32(); // sfVersion
  final numTables = reader.readUint16();
  reader.readUint16(); // searchRange
  reader.readUint16(); // entrySelector
  reader.readUint16(); // rangeShift

  print('Parsing $numTables tables...');

  // Read table records
  final tables = <String, TableRecord>{};
  for (int i = 0; i < numTables; i++) {
    final tag = reader.readTag();
    final checkSum = reader.readUint32();
    final offset = reader.readUint32();
    final length = reader.readUint32();
    tables[tag] = TableRecord(tag, checkSum, offset, length);
  }

  // Parse cmap table
  final cmapTable = tables['cmap']!;
  final postTable = tables['post']!;

  reader.seek(cmapTable.offset);
  reader.readUint16(); // version
  final cmapNumTables = reader.readUint16();

  // Find best cmap subtable
  int bestSubtableOffset = 0;
  int bestSubtableFormat = 0;

  for (int i = 0; i < cmapNumTables; i++) {
    reader.readUint16(); // platformID
    reader.readUint16(); // encodingID
    final subtableOffset = reader.readUint32();
    final pos = reader.tell();
    reader.seek(cmapTable.offset + subtableOffset);
    final format = reader.readUint16();

    if (format == 12 && bestSubtableFormat < 12) {
      bestSubtableFormat = 12;
      bestSubtableOffset = cmapTable.offset + subtableOffset;
    } else if (format == 4 && bestSubtableFormat < 4) {
      bestSubtableFormat = 4;
      bestSubtableOffset = cmapTable.offset + subtableOffset;
    }
    reader.seek(pos);
  }

  print('Using cmap format $bestSubtableFormat');

  // Parse format 12 cmap subtable
  final cmap = <int, int>{}; // code -> glyphIndex
  reader.seek(bestSubtableOffset);
  reader.readUint16(); // format
  reader.readUint16(); // reserved
  reader.readUint32(); // length
  reader.readUint32(); // language
  final numGroups = reader.readUint32();

  for (int i = 0; i < numGroups; i++) {
    final startCharCode = reader.readUint32();
    final endCharCode = reader.readUint32();
    final startGlyphID = reader.readUint32();

    for (int code = startCharCode; code <= endCharCode; code++) {
      cmap[code] = startGlyphID + (code - startCharCode);
    }
  }

  print('Glyphs mapped: ${cmap.length}');

  // Parse post table for glyph names
  reader.seek(postTable.offset);
  final postVersion = reader.readUint32();
  reader.readInt32(); // italicAngle
  reader.readInt16(); // underlinePosition
  reader.readInt16(); // underlineThickness
  reader.readUint32(); // isFixedPitch
  reader.readUint32(); // minMemType42
  reader.readUint32(); // maxMemType42
  reader.readUint32(); // minMemType1
  reader.readUint32(); // maxMemType1

  List<String> glyphNames = [];

  if (postVersion == 0x00020000) {
    final numGlyphs = reader.readUint16();
    print('Post table v2: $numGlyphs glyphs');

    final glyphNameIndices = List.generate(
      numGlyphs,
      (_) => reader.readUint16(),
    );
    final stringsStart = reader.tell();
    final macNames = _getMacGlyphNames();

    for (int i = 0; i < numGlyphs; i++) {
      final idx = glyphNameIndices[i];
      if (idx < 258) {
        glyphNames.add(idx < macNames.length ? macNames[idx] : '.notdef');
      } else {
        // Find Pascal string at correct position
        int stringIdx = 258;
        int pos = stringsStart;
        while (stringIdx < idx && pos < fontData.length) {
          final len = fontData[pos];
          pos += 1 + len;
          stringIdx++;
        }
        if (pos < fontData.length) {
          final len = fontData[pos];
          final name = String.fromCharCodes(
            fontData.sublist(pos + 1, pos + 1 + len),
          );
          glyphNames.add(name);
        } else {
          glyphNames.add('glyph$i');
        }
      }
    }
  }

  // Collect valid icons
  final iconList = <_IconEntry>[];
  final seenNames = <String, int>{};
  final skipNames = {'.notdef', '.null', 'nonmarkingreturn', 'CR', 'NULL'};
  final skipRanges = [
    [0x0000, 0x001F], // C0 controls
    [0x0080, 0x009F], // C1 controls
  ];

  for (final entry in cmap.entries) {
    final code = entry.key;
    final glyphIdx = entry.value;

    bool skip = false;
    for (final range in skipRanges) {
      if (code >= range[0] && code <= range[1]) {
        skip = true;
        break;
      }
    }
    if (skip) continue;

    var glyphName = glyphIdx < glyphNames.length
        ? glyphNames[glyphIdx]
        : 'glyph$glyphIdx';
    if (skipNames.contains(glyphName)) continue;

    // Handle duplicate space-like glyphs
    if (glyphName == 'space') {
      if (code == 0x0020) {
        // keep as 'space'
      } else if (code == 0x00A0) {
        glyphName = 'nobreakspace';
      } else {
        continue; // Skip other space variants
      }
    }

    var dartName = _glyphNameToDartName(glyphName, code);

    // Handle duplicates
    if (seenNames.containsKey(dartName)) {
      seenNames[dartName] = seenNames[dartName]! + 1;
      dartName = '${dartName}_${seenNames[dartName]}';
    } else {
      seenNames[dartName] = 1;
    }

    iconList.add(_IconEntry(code, dartName, glyphName));
  }

  // Sort by code point
  iconList.sort((a, b) => a.code.compareTo(b.code));

  print('Total icons: ${iconList.length}');

  // Generate Dart source
  final buffer = StringBuffer();
  buffer.writeln('''
// This file is auto-generated from HMSymbolVF.ttf
// Do not edit manually.
//
// HarmonyOS NEXT Symbol Icons for Flutter.

// ignore_for_file: constant_identifier_names
// ignore_for_file: document_private_apis

import 'package:flutter/widgets.dart';

/// HarmonyOS NEXT Symbol Icon data.
///
/// The [HMIcons] class provides static constants for all available
/// HarmonyOS Symbol icons based on the HMSymbolVF variable font.
///
/// {@tool snippet}
///
/// ```dart
/// Icon(HMIcons.wifi);
/// Icon(HMIcons.heart_fill);
/// ```
/// {@end-tool}
///
/// See also:
///  * [IconData], which describes a font icon.
///  * [Icon], a widget that draws an icon.
@staticIconProvider
class HMIcons {
  const HMIcons._();

  // === Font identifiers ===
  /// The font family name used by all icons in this class.
  static const String fontFamily = 'HMSymbolVF';

  /// The package name from which the font is loaded.
  static const String fontPackage = 'hm_icon';

''');

  for (final icon in iconList) {
    buffer.writeln(
      '  /// ${icon.glyphName} (U+${icon.code.toRadixString(16).toUpperCase().padLeft(4, '0')})',
    );
    buffer.writeln(
      "  static const ${icon.dartName} = IconData(0x${icon.code.toRadixString(16).toUpperCase().padLeft(4, '0')}, fontFamily: fontFamily, fontPackage: fontPackage);",
    );
    buffer.writeln();
  }

  buffer.writeln('}');

  // Write to package location
  final outputPath = '../lib/src/hm_icon_data.dart';
  File(outputPath).writeAsStringSync(buffer.toString());
  print('Written to $outputPath');

  // Generate icon list for preview / iteration
  final listBuffer = StringBuffer();
  listBuffer.writeln('''
// This file is auto-generated from HMSymbolVF.ttf
// Do not edit manually.
//
// Provides an iterable collection of all HMIcons for use in preview pages,
// search UIs, etc.

// ignore_for_file: constant_identifier_names

import 'hm_icon_data.dart';

/// A metadata entry for one icon in the collection.
class HMIconEntry {
  final String name;
  final IconData icon;
  final int codePoint;
  final String glyphName;

  const HMIconEntry({
    required this.name,
    required this.icon,
    required this.codePoint,
    required this.glyphName,
  });
}

/// All HarmonyOS Symbol icons as a const list, sorted by code point.
///
/// Useful for icon pickers, search, and preview pages.
const List<HMIconEntry> allHMIcons = [
''');
  for (final icon in iconList) {
    listBuffer.writeln(
      "  HMIconEntry(name: '${icon.dartName}', icon: HMIcons.${icon.dartName}, "
      "codePoint: 0x${icon.code.toRadixString(16).toUpperCase().padLeft(4, '0')}, "
      "glyphName: '${icon.glyphName}'),",
    );
  }
  listBuffer.writeln('];');

  final listOutputPath = '../lib/src/hm_icon_list.dart';
  File(listOutputPath).writeAsStringSync(listBuffer.toString());
  print('Written icon list to $listOutputPath');

  // Write barrel file
  final barrelContent = '''
/// HarmonyOS NEXT Symbol Icons for Flutter.
///
/// This package provides [HMIcons] - a collection of icon data constants
/// based on the HMSymbolVF variable font.
library;

export 'src/hm_icon_data.dart';
export 'src/hm_icon_list.dart';
''';
  File('../lib/hm_icon.dart').writeAsStringSync(barrelContent);
  print('Written barrel export');
}

class _IconEntry {
  final int code;
  final String dartName;
  final String glyphName;
  _IconEntry(this.code, this.dartName, this.glyphName);
}

String _glyphNameToDartName(String glyphName, int codePoint) {
  // Handle uniXXXX names
  if (glyphName.startsWith('uni') && glyphName.length == 7) {
    return 'u${glyphName.substring(3).toLowerCase()}';
  }

  // Replace separators
  var name = glyphName
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAll('.', '_');

  // Split and camelCase
  final parts = name.split('_').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'icon_${codePoint.toRadixString(16)}';

  final result = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    final part = parts[i].toLowerCase();
    if (i == 0) {
      result.write(part);
    } else {
      if (part.isNotEmpty) {
        result.write(part[0].toUpperCase() + part.substring(1));
      }
    }
  }

  var finalName = result.toString();

  // Dart keywords
  const keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  if (keywords.contains(finalName)) {
    finalName = '${finalName}_';
  }

  // Must start with lowercase or _
  if (finalName.isNotEmpty &&
      finalName[0].toUpperCase() == finalName[0] &&
      finalName[0] != '_') {
    finalName = '_$finalName';
  }

  // Can't start with digit
  if (finalName.isNotEmpty && RegExp(r'^\d').hasMatch(finalName)) {
    finalName = 'i$finalName';
  }

  return finalName.isEmpty ? 'icon_${codePoint.toRadixString(16)}' : finalName;
}

List<String> _getMacGlyphNames() {
  return [
    '.notdef',
    '.null',
    'nonmarkingreturn',
    'space',
    'exclam',
    'quotedbl',
    'numbersign',
    'dollar',
    'percent',
    'ampersand',
    'quotesingle',
    'parenleft',
    'parenright',
    'asterisk',
    'plus',
    'comma',
    'hyphen',
    'period',
    'slash',
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'colon',
    'semicolon',
    'less',
    'equal',
    'greater',
    'question',
    'at',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'bracketleft',
    'backslash',
    'bracketright',
    'asciicircum',
    'underscore',
    'grave',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'braceleft',
    'bar',
    'braceright',
    'asciitilde',
    'Adieresis',
    'Aring',
    'Ccedilla',
    'Eacute',
    'Ntilde',
    'Odieresis',
    'Udieresis',
    'aacute',
    'agrave',
    'acircumflex',
    'adieresis',
    'atilde',
    'aring',
    'ccedilla',
    'eacute',
    'egrave',
    'ecircumflex',
    'edieresis',
    'iacute',
    'igrave',
    'icircumflex',
    'idieresis',
    'ntilde',
    'oacute',
    'ograve',
    'ocircumflex',
    'odieresis',
    'otilde',
    'uacute',
    'ugrave',
    'ucircumflex',
    'udieresis',
    'dagger',
    'degree',
    'cent',
    'sterling',
    'section',
    'bullet',
    'paragraph',
    'germandbls',
    'registered',
    'copyright',
    'trademark',
    'acute',
    'dieresis',
    'notequal',
    'AE',
    'Oslash',
    'infinity',
    'plusminus',
    'lessequal',
    'greaterequal',
    'yen',
    'mu',
    'partialdiff',
    'summation',
    'product',
    'pi',
    'integral',
    'ordfeminine',
    'ordmasculine',
    'Omega',
    'ae',
    'oslash',
    'questiondown',
    'exclamdown',
    'logicalnot',
    'radical',
    'florin',
    'approxequal',
    'Delta',
    'guillemotleft',
    'guillemotright',
    'ellipsis',
    'nonbreakingspace',
    'Agrave',
    'Atilde',
    'Otilde',
    'OE',
    'oe',
    'endash',
    'emdash',
    'quotedblleft',
    'quotedblright',
    'quoteleft',
    'quoteright',
    'divide',
    'lozenge',
    'ydieresis',
    'Ydieresis',
    'fraction',
    'currency',
    'guilsinglleft',
    'guilsinglright',
    'fi',
    'fl',
    'daggerdbl',
    'periodcentered',
    'quotesinglbase',
    'quotedblbase',
    'perthousand',
    'Acircumflex',
    'Ecircumflex',
    'Aacute',
    'Edieresis',
    'Egrave',
    'Iacute',
    'Icircumflex',
    'Idieresis',
    'Igrave',
    'Oacute',
    'Ocircumflex',
    'apple',
    'Ograve',
    'Uacute',
    'Ucircumflex',
    'Ugrave',
    'dotlessi',
    'circumflex',
    'tilde',
    'macron',
    'breve',
    'dotaccent',
    'ring',
    'cedilla',
    'hungarumlaut',
    'ogonek',
    'caron',
    'Lslash',
    'lslash',
    'Scaron',
    'scaron',
    'Zcaron',
    'zcaron',
    'brokenbar',
    'Eth',
    'eth',
    'Yacute',
    'yacute',
    'Thorn',
    'thorn',
    'minus',
    'multiply',
    'onesuperior',
    'twosuperior',
    'threesuperior',
    'onehalf',
    'onequarter',
    'threequarters',
    'franc',
    'Gbreve',
    'gbreve',
    'Idotaccent',
    'Scedilla',
    'scedilla',
    'Cacute',
    'cacute',
    'Ccaron',
    'ccaron',
    'dcroat',
  ];
}
