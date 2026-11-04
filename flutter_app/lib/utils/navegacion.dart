import 'package:flutter/material.dart';

/// Llave global del Navigator: permite volver al Login desde cualquier parte
/// (por ejemplo, cuando la sesión expira y el servidor responde 401).
final GlobalKey<NavigatorState> navegadorGlobal = GlobalKey<NavigatorState>();
