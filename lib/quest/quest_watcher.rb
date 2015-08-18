module Quest

  class QuestWatcher

    def initialize
      @quest_dir = Quest.config[:quest_dir]
      @state_dir = Quest.config[:state_dir]
      @active_quest = Quest.config[:active_quest]
    end

    # The serverspec os function creates an infinite loop.
    # Setting it manually prevents the function from running.
    # Note that this is a temporary workaround, and this data is wrong!
    #set :os, {:family=>"darwin", :release=>"10", :arch=>"x86_64"}
    set :os, {}
    set :backend, :exec

    def run
      config = RSpec.configuration
      config.output_stream = File.open("/dev/null", "w")
      # This is some messy reach-around coding to get the JsonFormatter to work
      formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output_stream)
      reporter  = RSpec::Core::Reporter.new(config)
      config.instance_variable_set(:@reporter, reporter)
      loader = config.send(:formatter_loader)
      notifications = loader.send(:notifications_for, RSpec::Core::Formatters::JsonFormatter)
      reporter.register_listener(formatter, *notifications)
      RSpec::Core::Runner.run(["#{@quest_dir}/#{@active_quest}/#{@active_quest}_spec.rb"])
      File.open(File.join(@state_dir, "#{@active_quest}.json"), "w"){ |f| f.write(formatter.output_hash.to_json) }
      RSpec.reset
    end

    def load_active_quest
      Quest.configure_with(File.join(@state_dir, 'active_quest.json'))
    end

    def load_watchlist
      Quest.configure_with(File.join(@quest_dir, @active_quest, "config.json"))
    end

    def daemonize
      # The if condition is inspired by Rack. It's nice because it tells
      # us more or less what the Processs.daemon is doing under the hood.
      if RUBY_VERSION < "1.9"
        exit if fork
        Process.setsid
        exit if fork
        Dir.chdir "/"
        STDIN.reopen "/dev/null"
        STDOUT.reopen "/dev/null", "a"
        STDERR.reopen "/dev/null", "a"
      else
        Process.daemon
      end
    end

    def restart
      if @watcher
        @watcher.end
        @watcher.finalize
      end
      start
    end

    def start
      # I want to look into using a socket instead of signal to controll this
      # process.
      trap("HUP") do
        restart
      end
      load_active_quest
      load_watchlist
      run
      @watcher = FileWatcher.new(Quest.config[:quest_watch] + Quest.config[:global_watch])
      @watcher.watch do |f|
        run
      end
    end

  end
  
end
