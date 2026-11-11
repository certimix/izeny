import 'package:social_media_app/pocketbase/pb_compat.dart';

class Config {
  static initFirebase() async {
    await Firebase.initializeApp();
  }
}