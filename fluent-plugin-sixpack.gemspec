# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-sixpack"
  gem.version       = "0.1.0"
  gem.authors       = ["Naoki AINOYA"]
  gem.email         = ["ainonic@gmail.com"]
  gem.summary       = %q{Fluentd output plugin to post numbers to sixpack (by seatgeek)}
  gem.description   = %q{For sixpack, see http://sixpack.seatgeek.com }
  gem.homepage      = "https://github.com/ainoya/fluent-plugin-sixpack"
  gem.license       = "APLv2"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "fluent-mixin-config-placeholders"
  gem.add_runtime_dependency "resolve-hostname", ">= 0.0.4"
end
