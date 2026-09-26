import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvException implements Exception {
  final String message;
  const EnvException(this.message);

  @override
  String toString() => message;
}

/// Supabase credentials from the bundled `.env` asset.
///
/// `.env` ships inside every build, so it may only hold the project URL and
/// the publishable/anon key (public by design). A secret or service_role key
/// in it is refused at startup instead of being shipped to users.
class Env {
  final String supabaseUrl;
  final String supabaseKey;

  const Env({required this.supabaseUrl, required this.supabaseKey});

  /// Null when the file is missing or incomplete; throws [EnvException] when
  /// it contains a secret key.
  static Future<Env?> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      return null;
    }

    final unsafe = dotenv.env.entries.where((e) {
      final key = e.key.toUpperCase();
      return key.contains('SECRET') ||
          key.contains('SERVICE_ROLE') ||
          e.value.trim().startsWith('sb_secret_');
    });
    if (unsafe.isNotEmpty) {
      throw EnvException(
        'Remove ${unsafe.map((e) => e.key).join(', ')} from .env. That file is bundled into the app, '
        'so only the project URL and the publishable/anon key may be in it. '
        'Keep secret keys in supabase/.env.secret.',
      );
    }

    final url = (dotenv.maybeGet('SUPABASE_URL') ?? '').trim();
    final key = (dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ?? dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '').trim();
    if (url.isEmpty || key.isEmpty) return null;
    return Env(supabaseUrl: url, supabaseKey: key);
  }
}
