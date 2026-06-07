platform :ios, '13.0'

target 'NoSMS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'OneTimePassword', '~> 3.2'
  pod 'RxSwift', '~> 5.1'
  pod 'RxCocoa', '~> 5.1'
  pod 'SnapKit', '4.2.0'
  pod 'BiometricAuthentication'
  pod 'DynamicBlurView'
  pod 'RealmSwift'
  pod 'JXPatternLock'

  # Pods for NoSMS

  target 'NoSMSTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'NoSMSUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

