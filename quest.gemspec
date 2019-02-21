lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = 'quest'
  spec.version = '1.2.3'
  spec.authors = ['Services Portfolio']
  spec.email = ['services-portfolio@puppet.com']
  spec.summary = 'Track completion of configuration management tasks.'
  spec.description = "quest uses serverspec to track completion of configuration management related learning tasks."
  spec.homepage = 'http://github.com/puppetlabs/quest'
  spec.license = 'Apache 2.0'

  spec.files = %w( README.md LICENSE )
  spec.files += Dir['{bin,lib,locales}/**/*']
  spec.executables = ['quest','questctl','test_all_quests']
  spec.require_paths = ['lib']
  spec.add_dependency 'activesupport', '~> 4.2'
  spec.add_dependency 'serverspec', '~> 2.36'
  spec.add_dependency 'json', '~> 1.7'
  spec.add_dependency 'rack', '~> 1.6'
  spec.add_dependency 'gli', '~> 2.12'
  spec.add_dependency 'mono_logger', '~> 1.1'
  spec.add_dependency 'sinatra', '~> 1.4'
  spec.add_dependency 'highline', '~> 1.7'
  spec.add_dependency 'net-ssh', '~> 4.1'
  spec.add_dependency 'timers', '~> 4.1.0'
  spec.add_dependency 'hitimes', '~> 1.2'
  spec.add_dependency 'gettext-setup', '~> 0.24'
end
