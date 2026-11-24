#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint langswitch.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'langswitch'
  s.version          = '0.1.0'
  s.summary          = 'One-command per-app language switching for Flutter.'
  s.description      = <<-DESC
One-command per-app language switching for Flutter: Android 13+ and iOS system
language settings, persistence, and a ready-made picker.
                       DESC
  s.homepage         = 'https://github.com/YOUR_GITHUB_USERNAME/langswitch'
  s.license          = { :file => '../LICENSE' }
  s.source           = { :path => '.' }
  s.source_files = 'langswitch/Sources/langswitch/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'langswitch_privacy' => ['langswitch/Sources/langswitch/PrivacyInfo.xcprivacy']}
end
