import 'package:supabase_flutter/supabase_flutter.dart';

/// Single responsibility: Supabase project configuration and client accessor.
class SupabaseConfig {
  static const String url = 'https://joqxrpuavqepuxqemcpo.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvcXhycHVhdnFlcHV4cWVtY3BvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2MDc1NjMsImV4cCI6MjA4NzE4MzU2M30.Xvz4lAvTmUaqpdLjcCKshRVRazlSeRj7H8xe_msXmwQ';

  static SupabaseClient get client => Supabase.instance.client;
}
