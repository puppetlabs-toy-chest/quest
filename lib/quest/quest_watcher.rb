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
      RSpec::Core::Runner.run(["#{quest_dir}/#{active_quest}/#{active_quest}_spec.rb"])
      File.open(File.join(STATE_DIR, "#{active_quest}.json"), "w"){ |f| f.write(formatter.output_hash.to_json) }
      RSpec.reset
    end

    def restart_watcher
      if @watcher
        @watcher.pause
        @watcher.finalize
        @watcher.filenames = quest_watch
        @watcher.resume
      end
    end

    def write_pid
      begin
        File.open(PIDFILE, File::CREAT | File::EXCL | File::WRONLY){|f| f.write("#{Process.pid}") }
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
    end

    def start_watcher
      @watcher = FileWatcher.new(quest_watch)
      @watcher_thread = Thread.new(@watcher) do |watcher|
        watcher.watch do |f|
          run_specs
        end
      end
    end

    def run!
      check_pid
      Process.daemon if @daemonize
      write_pid
      trap_signals
      start_watcher
      thread = Thread.new { sleep }
      thread.join
    end

  end
end
