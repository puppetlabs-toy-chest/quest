module Quest

  class QuestWatcher

    include Quest::Messenger
    include Quest::SpecRunner

    def initialize(daemonize=true)
      @daemonize = daemonize
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
      test_current_quest_and_write_output
      Quest::LOGGER.info("Initializing watcher watching for changes in #{quest_watch}")
      @watcher = FileWatcher.new(quest_watch)
      @watcher_thread = Thread.new(@watcher) do |watcher|
        watcher.watch do |changed_file_path|
          Quest::LOGGER.info("Watcher triggered by a change to #{changed_file_path}")
          test_current_quest_and_write_output
        end
      end
    end

    def test_current_quest_and_write_output
      spec_output_hash = run_spec(active_quest_spec_path)
      write_json_output(spec_output_hash, active_quest_json_output_path)
      write_status_line(status_line_output_path)
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
      if @daemonize
        check_pid
        Process.daemon
      end
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
