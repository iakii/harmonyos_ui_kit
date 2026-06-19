// ignore_for_file: avoid_print, unused_local_variable

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

  int readUint32() {
    final v = _data.getUint32(_offset, Endian.big);
    _offset += 4;
    return v;
  }

  void seek(int pos) => _offset = pos;
  int tell() => _offset;
  String readTag() {
    final codes = List.generate(4, (_) => _data.getUint8(_offset++));
    return String.fromCharCodes(codes);
  }
}

class TableRecord {
  final String tag;
  final int offset;
  final int length;
  TableRecord(this.tag, this.offset, this.length);
}

void main() {
  final fontPath = '../fonts/HMSymbolVF.ttf';
  final fontData = File(fontPath).readAsBytesSync();
  final reader = TTFReader(ByteData.view(fontData.buffer));

  reader.readUint32(); // sfVersion
  final numTables = reader.readUint16();
  reader.readUint16();
  reader.readUint16();
  reader.readUint16();

  final tables = <String, TableRecord>{};
  for (int i = 0; i < numTables; i++) {
    final tag = reader.readTag();
    reader.readUint32(); // checkSum
    final offset = reader.readUint32();
    final length = reader.readUint32();
    tables[tag] = TableRecord(tag, offset, length);
  }

  // Check name table for font family name
  final nameTable = tables['name'];
  if (nameTable != null) {
    reader.seek(nameTable.offset);
    reader.readUint16(); // version
    final count = reader.readUint16();
    reader.readUint16(); // stringOffset
    final stringsStart = nameTable.offset + reader.tell() + count * 12 - 2;

    print('=== Name Table Records ===');
    for (int i = 0; i < count; i++) {
      final platformID = reader.readUint16();
      final encodingID = reader.readUint16();
      final languageID = reader.readUint16();
      final nameID = reader.readUint16();
      final length = reader.readUint16();
      final stringOffset = reader.readUint16();

      // nameID 1 = Font Family, nameID 2 = Font Subfamily, nameID 6 = PostScript Name
      if (nameID == 1 || nameID == 2 || nameID == 4 || nameID == 6) {
        final names = {
          1: 'Font Family',
          2: 'Font Subfamily',
          4: 'Full Name',
          6: 'PostScript Name',
          16: 'Typographic Family',
          17: 'Typographic Subfamily',
        };
        final pos = stringsStart + stringOffset;
        final bytes = fontData.sublist(pos, pos + length);
        String value;
        if (platformID == 3 || (platformID == 1 && encodingID == 0)) {
          value = String.fromCharCodes(bytes); // ASCII or UTF-16 BE
        } else if (platformID == 1 || platformID == 0) {
          value = String.fromCharCodes(bytes);
        } else {
          value = '<platform=$platformID, enc=$encodingID>';
        }
        print(
          '  nameID=${names[nameID] ?? nameID}: "$value" (platform=$platformID, lang=$languageID)',
        );
      }
    }
  }

  // Check cmap table - all subtables
  final cmapTable = tables['cmap'];
  if (cmapTable != null) {
    reader.seek(cmapTable.offset);
    final version = reader.readUint16();
    final numSubtables = reader.readUint16();

    print('\n=== CMAP Subtables ===');
    for (int i = 0; i < numSubtables; i++) {
      final platformID = reader.readUint16();
      final encodingID = reader.readUint16();
      final subtableOffset = reader.readUint32();
      final pos = reader.tell();

      reader.seek(cmapTable.offset + subtableOffset);
      final format = reader.readUint16();

      if (format == 4) {
        final length = reader.readUint16();
        final language = reader.readUint16();
        final segCountX2 = reader.readUint16();
        final segCount = segCountX2 ~/ 2;
        // Skip to end to get end codes
        reader.seek(cmapTable.offset + subtableOffset + 14);
        final endCodes = List.generate(segCount, (_) => reader.readUint16());
        reader.readUint16(); // reservedPad
        final startCodes = List.generate(segCount, (_) => reader.readUint16());

        int minCode = 0xFFFF;
        int maxCode = 0;
        int mappedSegments = 0;
        for (int s = 0; s < segCount; s++) {
          if (startCodes[s] != 0xFFFF || endCodes[s] != 0xFFFF) {
            if (startCodes[s] < minCode) minCode = startCodes[s];
            if (endCodes[s] > maxCode) maxCode = endCodes[s];
            mappedSegments++;
          }
        }
        print(
          '  Format 4: platform=$platformID, enc=$encodingID, lang=$language, segments: $mappedSegments mapped, range: U+${minCode.toRadixString(16).padLeft(4, '0')}..U+${maxCode.toRadixString(16).padLeft(4, '0')}',
        );
      } else if (format == 12) {
        reader.readUint16(); // reserved
        reader.readUint32(); // length
        final language = reader.readUint32();
        final nGroups = reader.readUint32();

        int minCode = 0xFFFFFFFF;
        int maxCode = 0;
        for (int g = 0; g < nGroups; g++) {
          final start = reader.readUint32();
          final end = reader.readUint32();
          reader.readUint32(); // startGlyph
          if (start < minCode) minCode = start;
          if (end > maxCode) maxCode = end;
        }
        print(
          '  Format 12: platform=$platformID, enc=$encodingID, lang=$language, groups: $nGroups, range: U+${minCode.toRadixString(16).padLeft(5, '0')}..U+${maxCode.toRadixString(16).padLeft(5, '0')}',
        );
      } else {
        print('  Format $format: platform=$platformID, enc=$encodingID');
      }

      reader.seek(pos);
    }
  }

  // Check if there's a format 4 subtable with PUA mappings
  print('\n=== Key Finding ===');
  print(
    'The font maps icons to U+F0000+ which is > U+FFFF (16-bit BMP limit).',
  );
  print('If the font only has format 4 cmap (BMP-only) on some platforms,');
  print('the glyphs at U+F0000+ will not be found.');
}
