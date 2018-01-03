Pod::Spec.new do |s|
  s.name         = "ZJRefreshControl"
  s.version      = "1.2"
  s.summary      = "ZJRefreshControl"
  s.description  = <<-EOS
  ZJRefreshControl
  EOS
  s.homepage     = "https://github.com/psvmc/ZJRefreshControl"
  s.license      = { :type => "MIT", :file => "License" }
  s.author             = { "psvmc" => "183518918@qq.com" }
  s.ios.deployment_target = '8.0'
  s.source       = { :git => "https://github.com/psvmc/ZJRefreshControl.git", :tag => s.version }
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files  = "ZJRefreshControl/Lib/ZJRefreshControl/*.swift"
    ss.framework  = "Foundation"
  end
end