# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pub_rx/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Noel Rappin"]
  gem.email         = ["noelrappin@gmail.com"]
  gem.description   = %q{Gem for publishing HTML, PDF, ePub, and Mobi from Markdown}
  gem.summary       = %q{Gem for publishing HTML, PDF, ePub, and Mobi from Markdown}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pub_rx"
  gem.require_paths = ["lib"]
  gem.version       = PubRx::VERSION
  gem.add_dependency('coderay')
  gem.add_dependency('rake')
  gem.add_dependency('grit')
  gem.add_dependency('sass')
  gem.add_dependency('princely')
  gem.add_dependency('watchr')
  gem.add_development_dependency('rspec')
end



