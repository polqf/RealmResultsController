Pod::Spec.new do |s|
  s.name         = "RealmResultsController"
  s.version      = "0.2.3"
  s.summary      = "A NSFetchedResultsController implementation for Realm written in Swift"
  s.homepage     = "https://github.com/teambox/RealmResultsController"
  s.license      = 'MIT'
  s.author       = "Redbooth"
  s.source       = { :git => "https://github.com/teambox/RealmResultsController.git", :tag => "0.2.3" }
  s.platform     = :ios, '8.0'
  s.source_files = 'Source'
  s.frameworks   = 'UIKit'
  s.requires_arc = true
  s.social_media_url = 'https://twitter.com/redboothhq'
  s.dependency 'RealmSwift'
end
