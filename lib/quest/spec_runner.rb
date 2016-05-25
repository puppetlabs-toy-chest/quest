module Quest
  module SpecRunner

    require 'serverspec'

    # The serverspec os function creates an infinite loop.
    # Setting it manually prevents the function from running.
    # Note that this is a temporary workaround, and this data is wrong!
    set :os, {}
    set :backend, :exec


    def run_spec(spec_path)

      config = RSpec.configuration
      formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output_stream)
      # Disable Standard out
      config.output_stream = File.open("/dev/null", "w")

      # This is some messy reach-around coding to get the JsonFormatter to work
      reporter  = RSpec::Core::Reporter.new(config)
      config.instance_variable_set(:@reporter, reporter)
      loader = config.send(:formatter_loader)
      notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)
      reporter.register_listener(formatter, *notifications)
      # End workaround

      # Run the test
      Quest::LOGGER.info("Beginning run of tests in #{spec_path}")
      RSpec::Core::Runner.run([spec_path])

      output_hash = formatter.output_hash

      # Clean up for next spec
      RSpec.reset
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
