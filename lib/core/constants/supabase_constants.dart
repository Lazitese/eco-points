/// Replace these with your actual Supabase project credentials.
/// Found in: Supabase Dashboard → Project Settings → API
class SupabaseConstants {
  SupabaseConstants._();

  static const String supabaseUrl = 'https://qsvpkzvdnubxfdnxwbcm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzdnBrenZkbnVieGZkbnh3YmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0ODYxOTMsImV4cCI6MjA5NDA2MjE5M30.RDiEmS8viMDKO0uzgd2Tvrz_vMQH--YgymBYTZNVwLQ';

  // Storage
  static const String photoBucket = 'verification-photos';

  // Tables
  static const String activitiesTable = 'activities';
  static const String profilesTable = 'profiles';
}
