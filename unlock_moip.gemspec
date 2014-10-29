$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "unlock_moip/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "unlock_moip"
  s.version     = UnlockMoip::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of UnlockMoip."
  s.description = "TODO: Description of UnlockMoip."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.6"

  s.add_development_dependency "sqlite3"
end
