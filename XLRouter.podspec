#
# Be sure to run `pod lib lint XLRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'XLRouter'
  s.version          = '0.1.0'
  s.summary          = 'A delightful View Router.'
  s.description      = 'A delightful View Router. Support argument check.'
  s.homepage         = 'https://github.com/TsichiChang/XLRouter'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tsichi' => 'zhang911010@gmail.com' }
  s.source           = { :git => 'https://github.com/TsichiChang/XLRouter.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'XLRouter/Classes/**/*'
  s.frameworks = 'Foundation'
end
