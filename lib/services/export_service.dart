import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'drawing_storage_service.dart';

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  Future<void> exportSessions({required bool asXlsx}) async {
    final starPathRecords =
        await DrawingStorageService.instance.loadStarPathRecords();
    final packageInfo = await PackageInfo.fromPlatform();
    final platform = Platform.operatingSystem;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportDir = Directory('${tempDir.path}/session_export_$timestamp');
    await exportDir.create(recursive: true);
    final imagesDir = Directory(p.join(exportDir.path, 'images'));
    await imagesDir.create(recursive: true);

    if (asXlsx) {
      final excel = Excel.createExcel();
      final starSheet = excel['StarPath'];
      starSheet.appendRow([
        'user_name',
        'session_id',
        'mode',
        'prompt_word',
        'saved_at',
        'image_path',
        'thumbnail_path',
        'stars_placed_count',
        'average_distance_between_stars',
        'path_length_total',
        'drawing_duration_seconds',
        'app_version',
        'platform',
      ]);
      for (final record in starPathRecords) {
        final imageFile = File(record.imagePath);
        final thumbFile = File(record.thumbnailPath);
        if (imageFile.existsSync()) {
          final newImagePath =
              p.join(imagesDir.path, p.basename(record.imagePath));
          await imageFile.copy(newImagePath);
        }
        if (thumbFile.existsSync()) {
          final newThumbPath =
              p.join(imagesDir.path, p.basename(record.thumbnailPath));
          await thumbFile.copy(newThumbPath);
        }
        starSheet.appendRow([
          record.userName,
          record.sessionId,
          record.mode,
          record.word ?? '',
          record.savedAt.toIso8601String(),
          record.imagePath,
          record.thumbnailPath,
          record.metrics['stars_placed_count'] ?? '',
          record.metrics['average_distance_between_stars'] ?? '',
          record.metrics['path_length_total'] ?? '',
          record.metrics['drawing_duration_seconds'] ?? '',
          packageInfo.version,
          platform,
        ]);
      }

      final fileBytes = excel.encode();
      final file = File(p.join(exportDir.path, 'sessions.xlsx'))
        ..writeAsBytesSync(fileBytes ?? Uint8List(0), flush: true);
      await _zipAndShare(exportDir);
      await Share.shareXFiles(
        [
          XFile('${exportDir.path}.zip'),
        ],
        text: 'Sesiones exportadas desde BrisaKids.',
        subject: 'Exportación de sesiones BrisaKids',
      );
    } else {
      final buffer = StringBuffer();
      buffer.writeln(
          'type,user_name,session_id,start_time,end_time,duration_seconds,metric_a,metric_b,metric_c,metric_d,mode,prompt_word,image_path,thumbnail_path,app_version,platform');
      for (final record in starPathRecords) {
        final imageFile = File(record.imagePath);
        final thumbFile = File(record.thumbnailPath);
        if (imageFile.existsSync()) {
          await imageFile.copy(
            p.join(imagesDir.path, p.basename(record.imagePath)),
          );
        }
        if (thumbFile.existsSync()) {
          await thumbFile.copy(
            p.join(imagesDir.path, p.basename(record.thumbnailPath)),
          );
        }
        buffer.writeln([
          'star_path',
          record.userName,
          record.sessionId,
          record.savedAt.toIso8601String(),
          record.savedAt.toIso8601String(),
          record.metrics['drawing_duration_seconds'] ?? '',
          record.metrics['stars_placed_count'] ?? '',
          record.metrics['average_distance_between_stars'] ?? '',
          record.metrics['path_length_total'] ?? '',
          record.metrics['save_pressed'] ?? '',
          record.mode,
          record.word ?? '',
          record.imagePath,
          record.thumbnailPath,
          packageInfo.version,
          platform,
        ].map(_escapeCsv).join(','));
      }
      final csvFile = File(p.join(exportDir.path, 'sessions.csv'));
      await csvFile.writeAsString(buffer.toString(), flush: true);
      await _zipAndShare(exportDir);
      await Share.shareXFiles(
        [
          XFile('${exportDir.path}.zip'),
        ],
        text: 'Sesiones exportadas desde BrisaKids.',
        subject: 'Exportación de sesiones BrisaKids',
      );
    }
  }

  Future<void> _zipAndShare(Directory exportDir) async {
    final archive = Archive();
    for (final file in exportDir.listSync(recursive: true)) {
      if (file is File) {
        final relativePath = p.relative(file.path, from: exportDir.path);
        archive.addFile(ArchiveFile(
          relativePath,
          file.lengthSync(),
          file.readAsBytesSync(),
        ));
      }
    }
    final zipData = ZipEncoder().encode(archive);
    final zipFile = File('${exportDir.path}.zip');
    await zipFile.writeAsBytes(zipData ?? Uint8List(0), flush: true);
  }

  String _escapeCsv(Object? value) {
    final str = value?.toString() ?? '';
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      final escaped = str.replaceAll('"', '""');
      return '"$escaped"';
    }
    return str;
  }
}
