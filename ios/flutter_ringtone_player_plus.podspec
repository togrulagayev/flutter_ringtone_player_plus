Pod::Spec.new do |s|
  s.name             = 'flutter_ringtone_player_plus'
  s.version          = '1.0.0'
  s.summary          = 'Play system ringtones, alarms, notification sounds and custom audio on Android and iOS, with looping, volume and playback state.'
  s.description      = <<-DESC
Play system ringtones, alarms, notification sounds and custom audio on Android and iOS, with looping, volume and playback state.
                       DESC
  s.homepage         = 'https://github.com/togrulagayev/flutter_ringtone_player_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Toghrul Aghayev' => 'noreply@togrulagayev.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_ringtone_player_plus/Sources/flutter_ringtone_player_plus/**/*.swift'
  s.resource_bundles = {
    'flutter_ringtone_player_plus_privacy' => ['flutter_ringtone_player_plus/Sources/flutter_ringtone_player_plus/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
