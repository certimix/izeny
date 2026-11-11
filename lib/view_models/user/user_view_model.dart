import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/foundation.dart';

class UserViewModel extends ChangeNotifier {
  User? user;
  FirebaseAuth auth = FirebaseAuth.instance;

  setUser() {
    user = auth.currentUser;
    notifyListeners();
  }
}
