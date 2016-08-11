require 'timers'

module Quest

  class QuestWatcher

    include Quest::SpecRunner

    def initialize(messenger)
      @messenger = messenger
      @timers = Timers::Group.new
      @lock = Mutex.new
    end

    def start_timer
      task_timer = @timers.now_and_every(5) do
        unless @lock.locked?
          @lock.lock
          check_active_quest
          @lock.unlock
        end
      end
      loop {@timers.wait}
    end

    def check_active_quest
      quest = @messenger.active_quest
      raw_status = run_spec(@messenger.spec_path(quest))
      @messenger.set_raw_status(quest, raw_status)
    end

    # This is the main function to set up and run the watcher process
    def run!
      load_helper
      start_timer
    end

  end
end
