module Quest

  class QuestWatcher

    def initialize
      # Require serverspec here because otherwise it conflicts with
      # the gli gem.
      require 'serverspec'
      # The serverspec os function creates an infinite loop.
      # Setting it manually prevents the function from running.
      # Note that this is a temporary workaround, and this data is wrong!
      #set :os, {:family=>"darwin", :release=>"10", :arch=>"x86_64"}
      set :os, {}
      set :backend, :exec

      @quest_dir = Quest.config[:quest_dir]
      @state_dir = Quest.config[:state_dir]
      @pidfile = Quest.config[:pidfile]
      @active_quest = Quest.config[:active_quest]
      Quest.initialize_state_dir # Create state_dir if it does not exist
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
      puts "Running #{@quest_dir}/#{@active_quest}/#{@active_quest}_spec.rb"
      RSpec::Core::Runner.run(["#{@quest_dir}/#{@active_quest}/#{@active_quest}_spec.rb"])
      puts "Saving RSpec output to " + File.join(@state_dir, "#{@active_quest}.json")
      File.open(File.join(@state_dir, "#{@active_quest}.json"), "w"){ |f| f.write(formatter.output_hash.to_json) }
      puts "resetting rspec"
      RSpec.reset
      puts "done resetting rspec"
    end

    def load_active_quest
      Quest.configure_with(File.join(@state_dir, 'active_quest.json'))
      @active_quest = Quest.config[:active_quest]
    end

    def load_watchlist
      Quest.configure_with(File.join(@quest_dir, @active_quest, "config.json"))
    end

    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      Dir.chdir "/"
      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null", "a"
      STDERR.reopen "/dev/null", "a"
    end

    def exit_watcher
      if @watcher
        puts "exiting watcher"
        @watcher.stop
        puts "finalizing watcher"
        @watcher.finalize
        puts "done finalizeing watcher"
      end
    end

    def write_pid
      begin
        File.open(@pidfile, File::CREAT | File::EXCL | File::WRONLY){|f| f.write("#{Process.pid}") }
        at_exit { File.delete(@pidfile) if File.exists?(@pidfile) }
      rescue Errno::EEXIST
        check_pid
        retry
      end
    end

    def check_pid
      case pid_status
      when :running, :not_owned
        puts "A server is already running. Check #{@pidfile}"
        exit 1
      when :dead
        File.delete(@pidfile)
      end
    end

    def pid_status
      return :exited unless File.exists?(@pidfile)
      pid = File.read(@pidfile).to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def trap_signals
      puts "setting up signal trapping"
      trap(:HUP) do
        puts 'Received SIGHUP. Restarting watcher.'
        restart
      end
    end

    def start_watcher
      puts "creating watcher for #{Quest.config[:quest_watch] + Quest.config[:global_watch]}"
      @watcher = FileWatcher.new(Quest.config[:quest_watch] + Quest.config[:global_watch])
      puts "running watcher"
      thread = Thread.new(@watcher) do |watcher|
        watcher.watch do |f|
          run_specs
        end
      end
    end

    def restart
      exit_watcher
      load_active_quest
      load_watchlist
      run_specs
      start_watcher
    end

    def run!
      #check_pid
      #daemonize
      write_pid
      trap_signals
      load_active_quest
      load_watchlist
      run_specs
      start_watcher
      thread = Thread.new { sleep }
      thread.join
    end

  end
end
