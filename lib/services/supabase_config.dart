import 'package:supabase_flutter/supabase_flutter.dart';

/// Your existing Supabase project, reused from the original HTML app.
/// The anon key is safe to ship client-side by design — it's the
/// public key, protected by Row Level Security policies on each table
/// (not a secret credential).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://fnkuwksbyejeeewrgyyq.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZua3V3a3NieWVqZWVld3JneXlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MDQ2MjMsImV4cCI6MjA5NjQ4MDYyM30.vm4UL-8rQ2HsXgbwwIDwTTE2SGgXTRSL45359THeaE8';

  static Future<void> init() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

/// Shorthand accessor used throughout the app instead of importing
/// supabase_flutter everywhere.
SupabaseClient get supabase => Supabase.instance.client;
