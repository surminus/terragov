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

  spec.required_ruby_version = '>= 2.2.2'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ['terragov']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "commander"
  spec.add_runtime_dependency "git"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "simplecov", ">= 0.8.2"
  spec.add_development_dependency 'coveralls', '>= 0.7.0'
end
