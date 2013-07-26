# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bank_job/version'

Gem::Specification.new do |spec|
  spec.name          = "bank_job"
  spec.version       = BankJob::VERSION
  spec.authors       = ["kkosuge"]
  spec.email         = ["root@kksg.net"]
  spec.description   = %q{銀行口座から預金情報を取ってくるライブラリ}
  spec.summary       = %q{銀行口座から預金情報を取ってくるライブラリ}
  spec.homepage      = "https://github.com/kkosuge/bank_job/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'mechanize', '~> 2.7'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
