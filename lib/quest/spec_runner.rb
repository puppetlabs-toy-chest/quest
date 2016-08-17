module Quest
  module SpecRunner

    require 'serverspec'

    # The serverspec os function creates an infinite loop.
    # Setting it manually prevents the function from running.
    # Note that this is a temporary workaround, and this data is wrong!
    set :os, {}
    set :backend, :exec

    def load_helper
      # Require a spec helper file if it exists
      if File.exist?(@messenger.spec_helper)
        load @messenger.spec_helper
        Quest::LOGGER.info("Loaded spec helper at #{@messenger.spec_helper}")
      else
        Quest::LOGGER.info("No spec_helper file found in #{@messenger.spec_helper}")
      end
    end

    def reset_rspec
      RSpec.clear_examples
      RSpec.reset

      # RSpec creates a new constant in the ExampleGroups module whenever you
      # load an example group. This accumulates state and will slowly leak
      # memory if we don't clean these up.
      RSpec::ExampleGroups.constants.each{ | c | RSpec::ExampleGroups.send(:remove_const, c) }
      Quest::LOGGER.info("RSpec reset")
      load_helper

      rspec_config = RSpec.configuration
      @formatter = RSpec::Core::Formatters::JsonFormatter.new(StringIO.new)

      # This uses private methods, so it may not respect semver. If things
      # break with a new version, be suspicious of this code.
      reporter  = RSpec::Core::Reporter.new(rspec_config)
      rspec_config.instance_variable_set(:@reporter, reporter)
      loader = rspec_config.send(:formatter_loader)
      notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)
      reporter.register_listener(@formatter, *notifications)
      # End workaround
    end

    def run_spec(spec_path)

      reset_rspec

      # Run the test
      Quest::LOGGER.info("Beginning run of tests in #{spec_path}")
      RSpec::Core::Runner.run([spec_path])

      return @formatter.output_hash
    end

  end
end
