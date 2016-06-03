source "https://github.com/GlobalTechnology/cocoapods-specs.git"

platform :ios, '7.0'


target "TheKeyOAuth2" do
  pod 'gtm-oauth2-thekey', '~>1.0'
end

post_install do |installer|
    installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
        configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
end
