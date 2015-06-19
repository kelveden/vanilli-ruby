# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "vanilli-ruby"
  spec.version       = "1.1.3"
  spec.authors       = ["Alistair Dutton"]
  spec.email         = ["kelveden@gmail.com"]

  spec.summary       = "Ruby bindings for vanilli"
  spec.description   = "Provides a ruby API for starting a vanilli server and interacting with it."
  spec.homepage      = "https://github.com/mixradio/vanilli-ruby"
  spec.license       = "BSD-3-Clause"

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rubocop", "~> 0.31"
  spec.add_runtime_dependency "rest-client", "~> 1.8"
  spec.add_runtime_dependency "json", "~> 1.8"
end
