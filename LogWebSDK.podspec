Pod::Spec.new do |s|
  s.name             = 'LogWebSDK'
  s.version          = '1.0.0'
  s.summary          = 'Zero-config CocoaLumberjack log viewer with built-in web server'
  s.description      = <<-DESC
LogWebSDK 是一个 iOS 日志收集 SDK，无需编写任何代码即可通过局域网实时查看 CocoaLumberjack 日志。
- 零配置集成，集成即用
- 内置 Web 服务器，支持浏览器实时查看
- Bonjour 服务发现，支持 macOS Console.app
- 支持日志分级筛选、正则匹配、断线重连
                       DESC

  s.homepage         = 'https://github.com/jieliangma/LogWebSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '马杰亮' => 'majieliang@yeah.net' }
  s.source           = { :git => 'https://github.com/jieliangma/LogWebSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files     = 'Classes/**/*.{h,m}'
  s.resource_bundles = {
    'LogWebSDK' => ['Classes/Resources/LogViewer.html']
  }

  s.dependency 'CocoaLumberjack'

  s.ios.frameworks = 'Foundation', 'Network', 'UIKit'

  s.info_plist = {
    'NSLocalNetworkUsageDescription' => '用于在局域网内提供日志查看服务',
    'NSBonjourServices' => ['_ioslog._tcp']
  }
end
