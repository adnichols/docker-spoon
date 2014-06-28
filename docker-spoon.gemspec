# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spoon/version'

Gem::Specification.new do |spec|
  spec.name          = "docker-spoon"
  spec.version       = Spoon::VERSION
  spec.authors       = ["Aaron Nichols"]
  spec.email         = ["anichols@trumped.org"]
  spec.summary       = %q{Create on-demand pairing environments in Docker}
  spec.description   = %q{Create on-demand pairing environments in Docker}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency('rdoc')
  spec.add_development_dependency('aruba')
  spec.add_development_dependency('rake', '~> 0.9.2')
  spec.add_dependency('methadone', '~> 1.4.0')
  spec.add_dependency('docker-api', '~> 1.11')
end
