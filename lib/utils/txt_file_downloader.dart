import 'package:flutter/foundation.dart';

import 'txt_file_downloader_stub.dart'
    if (dart.library.html) 'txt_file_downloader_web.dart';

Future<void> downloadTxtFile(String fileName, String contents) {
  debugPrint('TXT download via ${kIsWeb ? 'WEB' : 'NATIVE'} helper');
  return downloadTxtFileImpl(fileName, contents);
}
