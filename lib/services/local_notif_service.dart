// ============================================================
// FILE: lib/services/local_notif_service.dart (NEW)
// This is a "switch" — compile-time decides which file to actually use.
// Mobile build → local_notif_mobile.dart (real, unchanged behavior)
// Web build    → local_notif_stub.dart (no-op, avoids compile error)
// ============================================================

export 'local_notif_stub.dart'
if (dart.library.io) 'local_notif_mobile.dart';