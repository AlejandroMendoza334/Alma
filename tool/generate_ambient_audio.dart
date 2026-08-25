import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 22050;
const seconds = 24;
const crossfadeSeconds = 0.75;

void main() {
  final output = Directory('assets/audio')..createSync(recursive: true);
  _writeTrack(output, 'rain.wav', _rainTrack);
  _writeTrack(output, 'ocean.wav', _oceanTrack);
  _writeTrack(output, 'forest.wav', _forestTrack);
  _writeTrack(output, 'night.wav', _nightTrack);
}

void _writeTrack(Directory output, String name, List<double> Function(Random) createTrack) {
  final random = Random(42 + name.codeUnitAt(0));
  final samples = createTrack(random);
  _makeLoopSeamless(samples);
  final peak = samples.fold<double>(0, (current, value) => max(current, value.abs()));
  final gain = peak > 0.9 ? 0.9 / peak : 1.0;
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);
  _ascii(bytes, 0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  _ascii(bytes, 8, 'WAVEfmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  _ascii(bytes, 36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    bytes.setInt16(44 + index * 2, (samples[index] * gain * 32767).round(), Endian.little);
  }
  File('${output.path}/$name').writeAsBytesSync(bytes.buffer.asUint8List());
}

void _ascii(ByteData data, int offset, String value) {
  for (var index = 0; index < value.length; index++) {
    data.setUint8(offset + index, value.codeUnitAt(index));
  }
}

double _noise(Random random) => random.nextDouble() * 2 - 1;

void _makeLoopSeamless(List<double> samples) {
  final fadeSamples = (sampleRate * crossfadeSeconds).round();
  for (var index = 0; index < fadeSamples; index++) {
    final position = samples.length - fadeSamples + index;
    final blend = index / fadeSamples;
    samples[position] = samples[position] * (1 - blend) + samples[index] * blend;
  }
}

List<double> _rainTrack(Random random) {
  final samples = <double>[];
  var filteredNoise = 0.0;
  var drop = 0.0;
  var dropVelocity = 0.0;
  for (var index = 0; index < sampleRate * seconds; index++) {
    final time = index / sampleRate;
    filteredNoise = filteredNoise * 0.985 + _noise(random) * 0.015;
    if (random.nextDouble() < 0.00008) {
      dropVelocity = 0.25 + random.nextDouble() * 0.3;
    }
    drop += dropVelocity;
    dropVelocity *= 0.996;
    drop *= 0.992;
    final shimmer = sin(time * 2 * pi * (2800 + filteredNoise * 500)) * drop;
    samples.add(filteredNoise * 0.7 + _noise(random) * 0.025 + shimmer * 0.18);
  }
  return samples;
}

List<double> _oceanTrack(Random random) {
  final samples = <double>[];
  var foam = 0.0;
  var undertow = 0.0;
  for (var index = 0; index < sampleRate * seconds; index++) {
    final time = index / sampleRate;
    final swell = pow((sin(time * 2 * pi / 8) + 1) / 2, 2).toDouble();
    undertow = undertow * 0.997 + _noise(random) * 0.003;
    foam = foam * 0.94 + _noise(random) * 0.06;
    final waveNoise = _noise(random) * (0.025 + swell * 0.11);
    final lowWave = sin(time * 2 * pi / 7.5) * 0.055 + undertow * 0.35;
    samples.add(lowWave + waveNoise + foam * (0.025 + swell * 0.06));
  }
  return samples;
}

List<double> _forestTrack(Random random) {
  final samples = <double>[];
  var wind = 0.0;
  var bird = 0.0;
  for (var index = 0; index < sampleRate * seconds; index++) {
    final time = index / sampleRate;
    wind = wind * 0.995 + _noise(random) * 0.005;
    if (random.nextDouble() < 0.000015) bird = 0.12;
    bird *= 0.9994;
    final chirp = sin(time * 2 * pi * (900 + sin(time * 3) * 180)) * bird;
    final breeze = wind * (0.35 + 0.2 * sin(time * 2 * pi / 9));
    samples.add(breeze + _noise(random) * 0.018 + chirp);
  }
  return samples;
}

List<double> _nightTrack(Random random) {
  final samples = <double>[];
  var air = 0.0;
  var cricket = 0.0;
  for (var index = 0; index < sampleRate * seconds; index++) {
    final time = index / sampleRate;
    air = air * 0.998 + _noise(random) * 0.002;
    if (random.nextDouble() < 0.00003) cricket = 0.08;
    cricket *= 0.9992;
    final pulse = max(0.0, sin(time * 2 * pi * 4.2)) * cricket;
    samples.add(air * 0.45 + _noise(random) * 0.012 + pulse * sin(time * 2 * pi * 2100));
  }
  return samples;
}