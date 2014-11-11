$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "unlock_paypal/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "unlock_paypal"
  s.version     = UnlockPaypal::VERSION
  s.authors     = ["Daniel Weinmann"]
  s.email       = ["danielweinmann@gmail.com"]
  s.homepage    = "https://github.com/danielweinmann/unlock_paypal"
  s.summary     = "paypal-recurrring integration with Unlock"
  s.description = "paypal-recurrring integration with Unlock"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.6"
  s.add_dependency "unlock_gateway", "0.2.0"
  s.add_dependency "paypal-recurring"

  s.add_development_dependency "sqlite3"
end
