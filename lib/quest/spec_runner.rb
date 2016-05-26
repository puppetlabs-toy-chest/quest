module Quest
  module SpecRunner

    require 'serverspec'

    # The serverspec os function creates an infinite loop.
    # Setting it manually prevents the function from running.
    # Note that this is a temporary workaround, and this data is wrong!
    set :os, {}
    set :backend, :exec

    def run_specs
      Quest::LOGGER.info("run_pecs method started")
      config = RSpec.configuration

      # Disable Standard out
      config.output_stream = File.open("/dev/null", "w")

      # This is some messy reach-around coding to get the JsonFormatter to work
      formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output_stream)
      reporter  = RSpec::Core::Reporter.new(config)
      config.instance_variable_set(:@reporter, reporter)
      loader = config.send(:formatter_loader)
      notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)
      reporter.register_listener(formatter, *notifications)
      # End workaround

      # Run the test
      Quest::LOGGER.info("Beginning run of tests in #{spec_file}")
      RSpec::Core::Runner.run([spec_file])

      # Store test results
      File.open(json_output_file, "w"){ |f| f.write(formatter.output_hash.to_json) }
      Quest::LOGGER.info("RSpec output written to #{json_output_file}")

      # Store status line output
      status_line = status( options = {:brief => true, :color => false, :raw => false })
      File.open(status_line_output_file, "w"){ |f| f.write(status_line) }
      Quest::LOGGER.info("Status line written to #{status_line_output_file}")

      # Clean up for next spec
      RSpec.reset
      Quest::LOGGER.info("RSpec reset")
    end
  end
end
