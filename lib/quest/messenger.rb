module Quest
  class Messenger
    require 'sys/proctable'
    include Sys
    def initialize
      @quest_process = ProcTable.ps.select{ |p| p.comm == 'quest' }[0]
    end
    def send_reset
      Process.kill("HUP", @quest_process.pid)
    end
    def print_process
      puts @quest_process
    end 
  end
end

test = Quest::Messenger.new
test.print_process
