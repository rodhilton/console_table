# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "console_table"
  spec.version       = "0.2.1"
  spec.authors       = ["Rod Hilton"]
  spec.email         = ["consoletable@rodhilton.com"]
  spec.summary       = %q{Simplifies printing tables of information to commandline consoles}
  spec.description   = %q{Allows developers to define tables with specifically-sized columns, which can then have entries printed to them that are automatically formatted, truncated, and padded to fit in the console window.}
  spec.homepage      = "https://github.com/rodhilton/console_table"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'colorize', '~> 0.7'

  spec.add_runtime_dependency 'ruby-terminfo', '~> 0.1'
end
