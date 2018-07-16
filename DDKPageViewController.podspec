Pod::Spec.new do |s|

s.name         = 'DDKPageViewController'
s.version      = '0.9.0'
s.summary      = '基于UIPageViewController封装的分页控制器控件'
s.description  = '一个基于UIPageViewController封装的分页控制器控件，对UIPageViewController做了一些改善和处理，可以满足日常开发中的一些简单的分页视图的需求'
s.homepage     = 'https://github.com/Byxc/DDKPageViewController'
s.license      = 'MIT'
s.author             = { '白云心城' => "924698172@qq.com" }
s.ios.deployment_target = '8.0'
s.source       = { :git => 'https://github.com/Byxc/DDKPageViewController', :tag => s.version }
s.source_files  = 'DDKPageViewController/*.{h,m}'

s.framework  = 'UIKit'
s.requires_arc = true

end
