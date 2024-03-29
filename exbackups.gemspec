# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'exbackups/version'

Gem::Specification.new do |spec|
  spec.name          = "exbackups"
  spec.version       = Exbackups::VERSION
  spec.authors       = ["Jason Adam Young"]
  spec.email         = ["jayoung@extension.org"]
  spec.summary       = %q{Backup management tool for eXtension backups}
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency('thor', '>= 0.16.0')
  spec.add_dependency('toml', '~> 0.2.0')
  spec.add_dependency('rest-client', '~> 1.8.0')

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "httplog"


end
