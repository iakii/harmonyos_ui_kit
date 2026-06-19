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
  String readTag() {
    final codes = List.generate(4, (_) => _data.getUint8(_offset++));
    return String.fromCharCodes(codes);
  }
}

void main() {
  final fontPath = '../fonts/HMSymbolVF.ttf';
  final fontData = File(fontPath).readAsBytesSync();
  final reader = TTFReader(ByteData.view(fontData.buffer));

  reader.readUint32();
  final numTables = reader.readUint16();
  reader.readUint16();
  reader.readUint16();
  reader.readUint16();

  final tables = <String, int>{};
  final tableOffsets = <String, int>{};
  for (int i = 0; i < numTables; i++) {
    final tag = reader.readTag();
    reader.readUint32();
    final offset = reader.readUint32();
    final length = reader.readUint32();
    tables[tag] = offset;
    tableOffsets[tag] = length;
    print('  $tag: offset=$offset, len=$length');
  }

  // Parse name table
  final nameOff = tables['name'];
  if (nameOff != null) {
    reader.seek(nameOff);
    reader.readUint16(); // version
    final count = reader.readUint16();
    final storageOffset = reader.readUint16();
    final stringsStart = nameOff + storageOffset;

    print('\n=== Name Table ($count records) ===');
    for (int i = 0; i < count; i++) {
      final platformID = reader.readUint16();
      final encodingID = reader.readUint16();
      final languageID = reader.readUint16();
      final nameID = reader.readUint16();
      final length = reader.readUint16();
      final strOff = reader.readUint16();

      if (nameID == 1 ||
          nameID == 2 ||
          nameID == 4 ||
          nameID == 6 ||
          nameID == 16 ||
          nameID == 17) {
        final names = {
          1: 'Family',
          2: 'Subfamily',
          4: 'FullName',
          6: 'PostScript',
          16: 'TypoFamily',
          17: 'TypoSubfamily',
        };
        final absOff = stringsStart + strOff;
        String value;
        try {
          if (platformID == 3) {
            // UTF-16BE
            final codes = <int>[];
            for (int b = 0; b < length; b += 2) {
              codes.add((fontData[absOff + b] << 8) | fontData[absOff + b + 1]);
            }
            value = String.fromCharCodes(codes);
          } else {
            value = String.fromCharCodes(
              fontData.sublist(absOff, absOff + length),
            );
          }
        } catch (e) {
          value = '<error: $e>';
        }
        print(
          '  nameID=${names[nameID] ?? nameID}: "$value" (plat=$platformID, enc=$encodingID)',
        );
      }
    }
  }

  // Parse cmap subtables
  final cmapOff = tables['cmap'];
  if (cmapOff != null) {
    reader.seek(cmapOff);
    reader.readUint16(); // version
    final numSubtables = reader.readUint16();

    print('\n=== CMAP Subtables ===');
    for (int i = 0; i < numSubtables; i++) {
      final platformID = reader.readUint16();
      final encodingID = reader.readUint16();
      final subtableOff = reader.readUint32();
      final pos = reader._offset;

      reader.seek(cmapOff + subtableOff);
      final format = reader.readUint16();

      if (format == 4) {
        final length = reader.readUint16();
        final language = reader.readUint16();
        final segCountX2 = reader.readUint16();
        final segCount = segCountX2 ~/ 2;

        reader.seek(cmapOff + subtableOff + 14);
        final endCodes = List.generate(segCount, (_) => reader.readUint16());
        reader.readUint16(); // reservedPad
        final startCodes = List.generate(segCount, (_) => reader.readUint16());

        int minCode = 0xFFFF;
        int maxCode = 0;
        int mappedSegments = 0;
        for (int s = 0; s < segCount; s++) {
          if (startCodes[s] != 0xFFFF && startCodes[s] <= endCodes[s]) {
            if (startCodes[s] < minCode) minCode = startCodes[s];
            if (endCodes[s] > maxCode) maxCode = endCodes[s];
            mappedSegments++;
          }
        }
        print(
          '  Format 4: platform=$platformID, enc=$encodingID, lang=$language',
        );
        print(
          '    segments: $mappedSegments mapped, range: U+${minCode.toRadixString(16).padLeft(4, '0').toUpperCase()}..U+${maxCode.toRadixString(16).padLeft(4, '0').toUpperCase()}',
        );

        // Check if any icon PUA range is in format 4
        if (maxCode >= 0xF000) {
          print(
            '    *** Contains PUA range U+F000..U+FXXX - icons could be found via format 4!',
          );
        }
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
          '  Format 12: platform=$platformID, enc=$encodingID, lang=$language',
        );
        print(
          '    groups: $nGroups, range: U+${minCode.toRadixString(16).padLeft(6, '0').toUpperCase()}..U+${maxCode.toRadixString(16).padLeft(6, '0').toUpperCase()}',
        );
      } else {
        print('  Format $format: platform=$platformID, enc=$encodingID');
      }

      reader.seek(pos);
    }
  }
}
