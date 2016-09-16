require 'timers'

module Quest
  class QuestWatcher

    def initialize(messenger)
      @messenger = messenger
      @timers = Timers::Group.new
      @lock = Mutex.new
    end

    def start_timer
      task_timer = @timers.now_and_every(5) do
        unless @lock.locked?
          @lock.lock
          active_quest = @messenger.active_quest
          runner = Quest::RSpecRunner.new(@messenger.spec_path(active_quest), @messenger.spec_helper, @messenger.tmp_status_file)
          @messenger.set_raw_status(active_quest, runner.result)
          @lock.unlock
        end
      end
      loop {@timers.wait}
    end

    # This is the main function to set up and run the watcher process
    def run!
      start_timer
    end

  end
end
