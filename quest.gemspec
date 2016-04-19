lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'quest'
  spec.version = '0.0.5'
  spec.authors = ['Kevin Henner']
  spec.email = ['kevin@puppetlabs.com']
  spec.summary = 'Track completion of configuration management tasks.'
  spec.description = "quest uses serverspec to track completion of configuration management related learning tasks."
  spec.homepage = 'http://github.com/puppetlabs/quest'
  spec.license = 'Apache 2.0'

  spec.files = %w( README.md LICENSE )
  spec.files += Dir['{bin,lib,erb,public}/**/*']
  spec.executables = ['quest','questctl', 'ballad']
  spec.require_paths = ['lib']
  spec.add_dependency 'serverspec', '~> 2.19'
  spec.add_dependency 'json', '~> 1.7'
  spec.add_dependency 'filewatcher', '~> 0.5'
  spec.add_dependency 'rack', '~> 1.6'
  spec.add_dependency 'grape', '~> 0.12'
  spec.add_dependency 'gli', '~> 2.12'
end
