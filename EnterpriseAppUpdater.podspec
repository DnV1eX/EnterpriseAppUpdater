#  http://docs.cocoapods.org/specification.html

Pod::Spec.new do |s|

  s.name    = "EnterpriseAppUpdater"
  s.version = "1.2.1"
  s.summary = "Manage iOS In-House App Updates"

  s.description = <<-DESC
Enterprise App Updater loads app's manifest file, checks for a new version, provides an alert with patch notes and starts the update.
DESC

  s.screenshot          = "https://github.com/DnV1eX/EnterpriseAppUpdater/raw/master/Screenshot.png"
  s.homepage            = "https://github.com/DnV1eX/EnterpriseAppUpdater"
  s.license             = "Apache License, Version 2.0"
  s.author              = { "Alexey Demin" => "dnv1ex@ya.ru" }
  s.social_media_url    = "http://twitter.com/dnv1ex"

  s.swift_version           = "5.4"
  s.ios.deployment_target   = "9.0"
  
  s.source          = { :git => "https://github.com/DnV1eX/EnterpriseAppUpdater.git", :tag => "#{s.version}" }
  s.source_files    = "Sources/EnterpriseAppUpdater/*.swift"

end
