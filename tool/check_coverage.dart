import 'dart:io';

/// CI gate for production line coverage; LCOV files outside this project are ignored.
void main(List<String> args) {
  final input = File(args.isEmpty ? 'coverage/lcov.info' : args.single);
  if (!input.existsSync()) {
    stderr.writeln('Rapport LCOV manquant : ${input.path}');
    exitCode = 1;
    return;
  }
  final root = Directory.current.absolute.path.replaceAll('\\', '/');
  final files = <String, Map<int, bool>>{};
  String? current;
  for (final line in input.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      var source = line.substring(3).replaceAll('\\', '/');
      if (source.startsWith('$root/')) {
        source = source.substring(root.length + 1);
      }
      current = source.startsWith('lib/') ? source : null;
      if (current != null) {
        files.putIfAbsent(current, () => {});
      }
    } else if (line.startsWith('DA:') && current != null) {
      final fields = line.substring(3).split(',');
      final number = int.tryParse(fields[0]),
          hits = fields.length > 1 ? int.tryParse(fields[1]) : null;
      if (number == null || hits == null) {
        stderr.writeln('Ligne LCOV invalide : $line');
        exitCode = 1;
        return;
      }
      files[current]!.update(
        number,
        (covered) => covered || hits > 0,
        ifAbsent: () => hits > 0,
      );
    }
  }
  const thresholds = {
    'lib/': 85.0,
    'lib/domain/': 95.0,
    'lib/application/': 95.0,
    'lib/data/': 90.0,
    'lib/ui/': 80.0,
  };
  for (final entry in thresholds.entries) {
    final lines = files.entries
        .where((f) => f.key.startsWith(entry.key))
        .expand((f) => f.value.values)
        .toList();
    final covered = lines.where((v) => v).length;
    final rate = lines.isEmpty ? 0.0 : covered * 100 / lines.length;
    stdout.writeln(
      '${entry.key}: ${rate.toStringAsFixed(2)} % ($covered/${lines.length}), minimum ${entry.value.toStringAsFixed(0)} %',
    );
    if (lines.isEmpty || rate < entry.value) exitCode = 1;
  }
}
