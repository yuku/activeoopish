lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activeoopish/version"

Gem::Specification.new do |spec|
  spec.name            = 'activeoopish'
  spec.version         = ActiveOopish::VERSION
  spec.authors         = ['Yuku Takahashi']
  spec.email           = ['yuku@qiita.com']
  spec.summary         = 'Simple OOP-ish tools for Rails'
  spec.homepage        = 'https://github.com/yuku-t/activeoopish'
  spec.license         = 'MIT'

  spec.files           = `git ls-files -z`.split("\x0")
  spec.require_paths   = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'activemodel'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'shoulda-matchers'
end
