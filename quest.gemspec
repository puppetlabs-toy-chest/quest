lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'quest'
  spec.version = '0.0.1'
  spec.authors = ['Kevin Henner']
  spec.email = ['kevin@puppetlabs.com']
  spec.summary = 'Quest tracks completion of learning tasks and provides a RESTful API for monitoring their status.'

  spec.files = %w( README.md )
  spec.files += Dir['{bin,lib,erb,public}/**/*']
  spec.executables = ['quest','questctl']
  spec.require_paths = ['lib']
  spec.add_dependency 'serverspec'
  spec.add_dependency 'json'
  spec.add_dependency 'filewatcher'
  spec.add_dependency 'rack'
  spec.add_dependency 'grape'
  spec.add_dependency 'liquid'
  spec.add_dependency 'redcarpet'
  spec.add_dependency 'rouge', '~> 1.8', '!= 1.9.1'
  spec.add_dependency 'gli'
end
