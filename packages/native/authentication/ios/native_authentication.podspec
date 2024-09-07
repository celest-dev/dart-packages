Pod::Spec.new do |s|
  s.name             = 'native_authentication'
  s.version          = '0.0.1'
  s.summary          = 'Native support for package:native_authentication'
  s.description      = <<-DESC
Wraps ASWebAuthenticationSession for iOS.
                       DESC
  s.homepage         = 'https://celest.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Celest' => 'contact@celest.dev' }

  s.swift_version    = '5.0'
  s.platform         = :ios, '13.0'
  s.dependency       'Flutter'

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.requires_arc     = true
  s.frameworks       = 'AuthenticationServices', 'UIKit'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
