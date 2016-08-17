lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'quest'
  spec.version = '1.0.1'
  spec.authors = ['Kevin Henner']
  spec.email = ['kevin@puppetlabs.com']
  spec.summary = 'Track completion of configuration management tasks.'
  spec.description = "quest uses serverspec to track completion of configuration management related learning tasks."
  spec.homepage = 'http://github.com/puppetlabs/quest'
  spec.license = 'Apache 2.0'

  spec.files = %w( README.md LICENSE )
  spec.files += Dir['{bin,lib}/**/*']
  spec.executables = ['quest','questctl','test_all_quests']
  spec.require_paths = ['lib']
  spec.add_dependency 'activesupport', '~> 4.2'
  spec.add_dependency 'serverspec', '~> 2.36'
  spec.add_dependency 'json', '~> 1.7'
  spec.add_dependency 'rack', '~> 1.6'
  spec.add_dependency 'gli', '~> 2.12'
  spec.add_dependency 'mono_logger', '~> 1.1'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'highline'
  spec.add_dependency 'net-ssh'
  spec.add_dependency 'timers'
end
