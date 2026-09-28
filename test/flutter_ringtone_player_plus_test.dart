import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus_method_channel.dart';
import 'package:flutter_ringtone_player_plus/flutter_ringtone_player_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRingtonePlayerPlusPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRingtonePlayerPlusPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterRingtonePlayerPlusPlatform initialPlatform =
      FlutterRingtonePlayerPlusPlatform.instance;

  test('$MethodChannelFlutterRingtonePlayerPlus is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterRingtonePlayerPlus>(),
    );
  });

  test('getPlatformVersion', () async {
    final FlutterRingtonePlayerPlus flutterRingtonePlayerPlusPlugin =
        FlutterRingtonePlayerPlus();
    final MockFlutterRingtonePlayerPlusPlatform fakePlatform =
        MockFlutterRingtonePlayerPlusPlatform();
    FlutterRingtonePlayerPlusPlatform.instance = fakePlatform;

    expect(await flutterRingtonePlayerPlusPlugin.getPlatformVersion(), '42');
  });
}
