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
      if File.exists?(SPEC_HELPER)
        load SPEC_HELPER
        Quest::LOGGER.info("Loaded spec helper at #{SPEC_HELPER}")
      else
        Quest::LOGGER.info("No spec_helper file found in #{SPEC_HELPER}")
      end


      rspec_config = RSpec.configuration
      @formatter = RSpec::Core::Formatters::JsonFormatter.new(rspec_config.output_stream)
      # Disable Standard out
      rspec_config.output_stream = File.open("/dev/null", "w")

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

      # Run the test
      Quest::LOGGER.info("Beginning run of tests in #{spec_path}")
      RSpec::Core::Runner.run([spec_path])

      output_hash = @formatter.output_hash

      # Clean up for next spec
      RSpec.clear_examples
      Quest::LOGGER.info("RSpec reset")

      return output_hash
    end

    def write_json_output(output_hash, path)
      File.open(path, "w"){ |f| f.write(output_hash.to_json) }
      Quest::LOGGER.info("RSpec output written to #{path}")
    end

    def write_status_line(path)
      status_line = status( options = {:brief => true, :color => false, :raw => false })
      File.open(path, "w"){ |f| f.write(status_line) }
      Quest::LOGGER.info("Status line written to #{path}")
    end

  end
end
