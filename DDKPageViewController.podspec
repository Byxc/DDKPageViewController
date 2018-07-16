Pod::Spec.new do |s|

s.name         = 'DDKPageViewController'
s.version      = '0.9.0'
s.summary      = '基于UIPageViewController封装的分页控制器控件'
s.description  = '一个使用UIPageViewController封装实现的分页控件，在UIPageViewController的基础上做了一些改善以满足日常简单的分页需求'
s.homepage     = 'https://github.com/Byxc/DDKPageViewController'
s.license      = 'MIT'
s.author             = { '白云心城' => "924698172@qq.com" }
s.ios.deployment_target = '8.0'
s.source       = { :git => 'https://github.com/Byxc/DDKPageViewController', :tag => s.version }
s.source_files  = 'DDKPageViewController/*.{h,m}'

s.framework  = 'UIKit'
s.requires_arc = true

end
