# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'integer_set/version'

Gem::Specification.new do |spec|
  spec.name          = "integer_set"
  spec.version       = IntegerSet::VERSION
  spec.authors       = ["Jkr2255"]
  spec.email         = ["magnesium.oxide.play@gmail.com"]

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.licenses      = %w|Ruby BSD-2-Clause|


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '2.0.0'

  spec.add_dependency 'bit_counter', '>= 0.1.0'
  spec.add_dependency 'backports', '>= 3.6.6'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
