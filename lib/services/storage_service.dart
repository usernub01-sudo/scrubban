import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucket = 'product-images';

  /// يرفع صورة ويرجّع الـPublic URL
  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // اسم فريد لتجنّب التصادم
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${timestamp}_$safeName';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // الرابط العام
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// يحذف صورة (اختياري — لو حبيت تستخدمها لاحقًا)
  Future<void> deleteProductImage(String publicUrl) async {
    // نستخرج المسار من الرابط
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final idx = segments.indexOf(_bucket);
    if (idx == -1 || idx + 1 >= segments.length) return;

    final path = segments.sublist(idx + 1).join('/');
    await _client.storage.from(_bucket).remove([path]);
  }
}
