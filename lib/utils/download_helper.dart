import 'download_stub.dart'
    if (dart.library.html) 'download_web.dart';

void downloadApk() {
  triggerApkDownload('/downloads/IZeny.apk');
}

