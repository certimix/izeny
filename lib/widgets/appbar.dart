import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

AppBar header(context) {
  return AppBar(
    title: Text(
      '𝗜𝓩𝓮𝓷𝔂',
      style: TextStyle(
        fontFamily: 'NotoSansMath',
        fontWeight: FontWeight.w900,
        fontSize: 22.0,
      ),
    ),
    centerTitle: true,
    actions: [Padding(
      padding: const EdgeInsets.only(right:20.0),
      child: Icon(Ionicons.notifications_outline),
    )],
  );
}
