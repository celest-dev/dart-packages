Pod::Spec.new do |s|
  s.name             = 'native_authentication'
  s.version          = '0.0.1'
  s.summary          = 'Native support for package:native_authentication'
  s.description      = <<-DESC
Wraps ASWebAuthenticationSession for macOS.
                       DESC
  s.homepage         = 'https://celest.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Celest' => 'contact@celest.dev' }

  s.swift_version = '5.0'
  s.platform = :osx, '10.15'
  s.dependency 'FlutterMacOS'

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.compiler_flags = ['-fno-objc-arc']
  s.frameworks = 'AuthenticationServices', 'AppKit'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
