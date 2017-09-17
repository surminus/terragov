# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'terragov/version'

Gem::Specification.new do |spec|
  spec.name          = "terragov"
  spec.version       = Terragov::VERSION
  spec.authors       = ["Laura Martin"]
  spec.email         = ["surminus@gmail.com"]

  spec.summary       = "Wrapper for GOV.UK Terraform deployments."
  spec.description   = "GOV.UK deploy infrastructure using Terraform. This is a wrapper to help deployments."
  spec.homepage      = "https://github.com/surminus/terragov"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ['terragov']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "commander"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
