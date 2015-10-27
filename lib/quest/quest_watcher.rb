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
      #set :os, {:family=>"darwin", :release=>"10", :arch=>"x86_64"}
      set :os, {}
      set :backend, :exec

      @daemonize = daemonize

    end

    def run_specs
      config = RSpec.configuration
      config.output_stream = File.open("/dev/null", "w")
      # This is some messy reach-around coding to get the JsonFormatter to work
      formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output_stream)
      reporter  = RSpec::Core::Reporter.new(config)
      config.instance_variable_set(:@reporter, reporter)
      loader = config.send(:formatter_loader)
      notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)
      reporter.register_listener(formatter, *notifications)
      spec_file = File.join(quest_dir, active_quest, "#{active_quest}_spec.rb")
      Quest::LOGGER.info("Running tests in #{spec_file}")
      RSpec::Core::Runner.run([spec_file])
      output_file = File.join(STATE_DIR, "#{active_quest}.json")
      Quest::LOGGER.info("Writing RSpec output to #{output_file}")
      File.open(output_file, "w"){ |f| f.write(formatter.output_hash.to_json) }
      Quest::LOGGER.info("Resetting RSpec")
      RSpec.reset
    end

    def restart_watcher
      if @watcher
        Quest::LOGGER.info("Pausing watcher")
        @watcher.pause
        Quest::LOGGER.info("Finalizing watcher")
        @watcher.finalize
        Quest::LOGGER.info("Setting watcher filenames to #{quest_watch}")
        @watcher.filenames = quest_watch
        Quest::LOGGER.info("Resuming watcher")
        @watcher.resume
      else
        Quest::LOGGER.info("No watcher instance found. Skipping watcher restart.")
      end
    end

    def write_pid
      Quest::LOGGER.info("Writing PID to #{PIDFILE}")
      begin
        File.open(PIDFILE, File::CREAT | File::EXCL | File::WRONLY){|f| f.write("#{Process.pid}") }
        at_exit { File.delete(PIDFILE) if File.exists?(PIDFILE) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end

    def check_pid
      Quest::LOGGER.info('Checking PID')
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
      Quest::LOGGER.info("Setting trap for HUP signal")
      trap(:HUP) do
        restart_watcher
      end
    end

    def start_watcher
      Quest::LOGGER.info('Starting initial spec run')
      run_specs
      Quest::LOGGER.info("Initializing watcher watching for changes in #{quest_watch}")
      @watcher = FileWatcher.new(quest_watch)
      @watcher_thread = Thread.new(@watcher) do |watcher|
        watcher.watch do |f|
          run_specs
        end
      end
    end

    def load_helper
      # Require a spec_helper file if it exists
      spec_helper = File.join(quest_dir, 'spec_helper.rb')
      if File.exists?(spec_helper)
        require File.join(spec_helper)
        Quest::LOGGER.info("Required #{spec_helper}")
      else
        Quest::LOGGER.info("No spec_helper.rb file found in #{quest_dir}")
      end
    end

    def run!
      check_pid
      Process.daemon if @daemonize
      write_pid
      trap_signals
      load_helper
      start_watcher
      thread = Thread.new { sleep }
      thread.join
    end

  end
end
