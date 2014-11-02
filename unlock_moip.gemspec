$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "unlock_moip/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "unlock_moip"
  s.version     = UnlockMoip::VERSION
  s.authors     = ["Daniel Weinmann"]
  s.email       = ["danielweinmann@gmail.com"]
  s.homepage    = "https://github.com/danielweinmann/unlock_moip"
  s.summary     = "Moip Assinaturas integration for Unlock"
  s.description = "Moip Assinaturas integration for Unlock"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.6"
  s.add_dependency "moip-assinaturas", "0.4.2"
  s.add_dependency "slim"
  s.add_dependency "slim-rails"

  s.add_development_dependency "sqlite3"
end
