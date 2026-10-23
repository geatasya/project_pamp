import 'package:flutter/material.dart';

/// Layar lebar (web / tablet) memakai sidebar & layout 2 kolom.
bool isWideLayout(BuildContext context) =>
    MediaQuery.of(context).size.width >= 900;
