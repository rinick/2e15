///  Hashdown is free software: you can redistribute it and/or modify
///  it under the terms of the GNU General Public License as published by
///  the Free Software Foundation, either version 3 of the License, or
///  (at your option) any later version.

part of hashdown;

abstract class XCodec {
  static XCodec getCodec(String name) {
    if (name.startsWith('link')) {
      return new Base64UrlCodec();
    }
    if (name.startsWith('base64')) {
      return new Base64Codec();
    }
    if (name.startsWith('tadpole')) {
      return new TadpoleCodec();
    }
    
    if (name.startsWith('shadow')) {
      return new ShadowCodeCodec();
    }
    return new Base2e15Codec();
  }
  String encode(List<int> bytes);
  List<int> decode(String str);
}

class Base2e15Codec implements XCodec {
  List<int> decode(String str) {
    return Base2e15.decode(str);
  }

  String encode(List<int> bytes) {
    return Base2e15.encode(bytes);
  }
}

class Base64Codec implements XCodec {
  List<int> decode(String str) {
    return BASE64.decode(str);
  }

  String encode(List<int> bytes) {
    return BASE64.encode(bytes);
  }
}

class Base64UrlCodec implements XCodec {
  static String url = 'http://www.hashdown.net/#';

  List<int> decode(String str) {
    int pos = str.indexOf('#');
    if (pos > -1) {
      str = str.substring(pos + 1);
    }
    // append =
    int len = str.length;
    switch (len % 4) {
      case 3:
        str = str + '=';
        break;
      case 2:
        str = str + '==';
        break;
      case 1: // impossible
        str = str + '===';
        break;
    }
    return BASE64URL.decode(str);
  }

  String encode(List<int> bytes) {
    String base64 = BASE64URL.encode(bytes);
    if (base64.endsWith('==')) base64 = base64.substring(0, base64.length - 2);
    else if (base64.endsWith('=')) base64 =
        base64.substring(0, base64.length - 1);
    return '$url$base64';
  }
}

class TadpoleCodec implements XCodec {
  List<int> decode(String str) {
    return TadpoleCode.decode(str);
  }

  String encode(List<int> bytes) {
    return TadpoleCode.encode(bytes);
  }
}
class ShadowCodeCodec implements XCodec {
  List<int> decode(String str) {
    return ShadowCode.decode(str, [-1, 0xC1]);
  }

  String encode(List<int> bytes) {
    return ShadowCode.encode(bytes, [0xC0, 0xC1]);
  }
}
