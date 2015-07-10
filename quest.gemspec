lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'quest'
  spec.version = '0.0.1'
  spec.authors = ['Kevin Henner']
  spec.email = ['kevin@puppetlabs.com']
  spec.summary = 'Filesystem monitoring and RESTful API for tracking status in test-driven learning.'

  spec.files = %w( README.md Rakefile )
  spec.files += Dir['{bin,lib,spec}/**/*']
  spec.executables = ['quest']
  spec.require_paths = ['lib']
  spec.add_dependency 'serverspec'
  spec.add_dependency 'json'
  spec.add_dependency 'composite_primary_keys'
  spec.add_dependency 'rack'
  spec.add_dependency 'grape'
  spec.add_dependency 'filewatcher'
end
