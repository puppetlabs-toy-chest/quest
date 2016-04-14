module Quest

  class QuestWatcher

    include Quest::Messenger

    def initialize(daemonize=true)
      # Require serverspec here because otherwise it conflicts with
      # the gli gem.
      require 'serverspec'
      require 'rspec/autorun'

      # The serverspec os function creates an infinite loop.
      # Setting it manually prevents the function from running.
      # Note that this is a temporary workaround, and this data is wrong!
      set :os, {}
      set :backend, :exec

      @daemonize = daemonize

    end

    def run_specs
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

    def restart_watcher
      if @watcher
        @watcher.pause
        Quest::LOGGER.info("Watcher paused")
        @watcher.finalize
        Quest::LOGGER.info("Watcher finalized pending runs")
        @watcher.filenames = quest_watch
        Quest::LOGGER.info("Watcher file names set to #{quest_watch}")
        @watcher.resume
        Quest::LOGGER.info("Watcher resumed")
      else
        Quest::LOGGER.info("No watcher instance found. Skipping watcher restart.")
      end
    end

    def write_pid
      begin
        File.open(PIDFILE, File::CREAT | File::EXCL | File::WRONLY){|f| f.write("#{Process.pid}") }
        Quest::LOGGER.info("PID written to #{PIDFILE}")
        at_exit { File.delete(PIDFILE) if File.exists?(PIDFILE) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end

    def check_pid
      case pid_status
      when :running, :not_owned
        puts "The quest watcher is already running. Check #{PIDFILE}"
        exit 1
      when :dead
        File.delete(PIDFILE)
      end
    end

    def pid_status
      return :exited unless File.exists?(PIDFILE)
      pid = File.read(PIDFILE).to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def trap_signals
      trap(:HUP) do
        restart_watcher
      end
      Quest::LOGGER.info("Trap for HUP signal set")
    end

    def start_watcher
      Quest::LOGGER.info('Starting initial spec run')
      run_specs
      Quest::LOGGER.info("Initializing watcher watching for changes in #{quest_watch}")
      @watcher = FileWatcher.new(quest_watch)
      @watcher_thread = Thread.new(@watcher) do |watcher|
        watcher.watch do |changed_file_path|
          Quest::LOGGER.info("Watcher triggered by a change to #{changed_file_path}")
          run_specs
        end
      end
    end

    def load_helper
      # Require a spec_helper file if it exists
      if File.exists?(spec_helper)
        require spec_helper
        Quest::LOGGER.info("Loaded spec helper at #{spec_helper}")
      else
        Quest::LOGGER.info("No spec_helper file found in #{quest_dir}")
      end
    end

    # This is the main function to set up and run the watcher process
    def run!
      check_pid
      Process.daemon if @daemonize
      write_pid
      trap_signals
      load_helper
      start_watcher
      # Keep a sleeping thread to handle signals.
      thread = Thread.new { sleep }
      thread.join
    end

  end
end
