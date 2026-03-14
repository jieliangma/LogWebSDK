Pod::Spec.new do |s|
  s.name             = 'LogWebSDK'
  s.version          = '1.0.0'
  s.summary          = 'Zero-config CocoaLumberjack log viewer with built-in web server'
  s.description      = <<-DESC
LogWebSDK 是一个 iOS 日志收集 SDK，无需编写任何代码即可通过局域网实时查看 CocoaLumberjack 日志。
- 零配置集成，集成即用
- 内置 Web 服务器，支持浏览器实时查看
- 支持 NSLogger macOS Viewer
- 支持日志分级筛选、正则匹配、断线重连
                       DESC

  s.homepage         = 'https://github.com/jieliangma/LogWebSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '马杰亮' => 'majieliang@yeah.net' }
  s.source           = { :git => 'https://github.com/jieliangma/LogWebSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.default_subspec = 'NSLogger'

  # ── Core ──────────────────────────────────────────────────────────────────
  s.subspec 'Core' do |core|
    core.source_files     = 'Classes/Core/**/*.{h,m}'
    core.resource_bundles = { 'LogWebSDK' => ['Classes/Resources/LogViewer.html'] }
    core.ios.frameworks   = 'Foundation', 'Network', 'UIKit'
    core.dependency 'CocoaLumberjack'
  end

  # ── NSLogger（默认启用）────────────────────────────────────────────────────
  s.subspec 'NSLogger' do |ns|
    ns.source_files = 'Classes/NSLogger/**/*.{h,m}'
    ns.dependency 'LogWebSDK/Core'
    ns.dependency 'NSLogger', '~> 1.9'
  end
end
