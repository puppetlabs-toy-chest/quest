lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'Quest'
  spec.version = '0.0.1'
  spec.authors = ['Kevin Henner']
  spec.email = ['kevin@puppetlabs.com']
  spec.summary = 'Quest tracks completion of learning tasks and provides a RESTful API for monitoring their status.'

  spec.files = %w( README.md )
  spec.files += Dir['{bin,lib,spec}/**/*']
  spec.executables = ['quest','ballad']
  spec.require_paths = ['lib']
  spec.add_dependency 'serverspec'
  spec.add_dependency 'json'
  spec.add_dependency 'filewatcher'
  spec.add_dependency 'rack'
  spec.add_dependency 'grape'
end
