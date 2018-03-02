///  Hashdown is free software: you can redistribute it and/or modify
///  it under the terms of the GNU General Public License as published by
///  the Free Software Foundation, either version 3 of the License, or
///  (at your option) any later version.

part of hashdown;

class HashdownCompress {
  static List<int> compressString(String str, HashdownParams params) {
    List<int> utf8 = UTF8.encode(str);
    List<int> utf16 = UTF16.encode(str);
    List<int> rslt = utf8;
    int min = utf8.length;
    params.mode = HashdownParams.MODE_UTF8;

    if (params.compressed == 1) {
      // assume compression is not needed
      params.compressed = 0;
      // don't compress short string
      if (utf8.length > 16 && utf16.length > 16) {
        if (utf16.length * 1.125 > utf8.length) {
          List<int> utf8c = compress(utf8);
          if (min > utf8c.length) {
            rslt = utf8c;
            min = utf8c.length;
            params.compressed = 1;
          }
        }
        if (utf8.length * 1.125 > utf16.length) {
          List<int> utf16c = compress(utf16);
          if (min > utf16c.length) {
            rslt = utf16c;
            min = utf16c.length;
            params.mode = HashdownParams.MODE_UTF16;
            params.compressed = 1;
          }
        }
      }
    }
    if (min > utf16.length) {
      if (params.protection == HashdownParams.PROTECT_PASSWORD) {
        // add extra 0 to validate utf16
        rslt = []
          ..addAll(utf16)
          ..add(0);
      } else {
        rslt = utf16;
      }
      params.mode = HashdownParams.MODE_UTF16;
      params.compressed = 0;
    }
    return rslt;
  }
  static List<int> compressFile(HashdownFile file, HashdownParams params) {
    List<int> data = file.encode();
    params.mode = HashdownParams.MODE_FILE;
    if (params.compressed == 1) {
      List<int> compressed = compress(data);
      if (compressed.length < data.length) {
        return compressed;
      }
    }
    params.compressed = 0;
    return data;
  }
  static Object decompressAuto(List<int> data, HashdownParams params) {
    if (params.compressed == 1) {
      data = decompress(data);
    }
    if (params.mode == HashdownParams.MODE_UTF8) {
      return UTF8.decode(data);
    }
    if (params.mode == HashdownParams.MODE_UTF16) {
      return UTF16.decode(data);
    }
    if (params.mode == HashdownParams.MODE_FILE) {
      new HashdownFile.decode(data);
    }
    return data;
  }

  static LZMA.Params _params = new LZMA.Params();

  static List<int> compress(List<int> data) {
    var inStream = new LZMA.InStream(data);
    var outStream = new LZMA.OutStream();
    var encoder = new LZMA.Encoder();
    encoder.setDictionarySize(1 << _params.dictionarySize);
    encoder.setNumFastBytes(_params.fb);
    encoder.setMatchFinder(_params.matchFinder);
    encoder.setLcLpPb(_params.lc, _params.lp, _params.pb);
    encoder.setEndMarkerMode(_params.eos);

    var sizes = encodeLength(data.length);
    outStream.writeBlock(sizes, 0, sizes.length);

    encoder.code(inStream, outStream, -1, -1);
    return outStream.data;
  }

  static List<int> decompress(List<int> data) {
    var inStream = new LZMA.InStream(data);
    var outStream = new LZMA.OutStream();
    var decoder = new LZMA.Decoder();
    decoder.setDecoderProperties([93, 0, 0, 128, 0]);

    int size = decodeLength(inStream);

    if (!decoder.decode(inStream, outStream, size)) {
      throw 'decompress failed';
    }
    return outStream.data;
  }
  static List<int> encodeLength(int n) {
    List<int> list = new List<int>();
    while (n > 127) {
      list.add((n & 127) | 128);
      n = n >> 7;
    }
    list.add(n);
    return list;
  }
  static int decodeLength(LZMA.InStream stream) {
    int n = 0;
    int shift = 0;
    int byte;
    do {
      byte = stream.read();
      n |= (byte & 127) << shift;
      shift += 7;
    } while (byte > 127);
    return n;
  }
}
