# -*- encoding : utf-8 -*-
module Quest
  module Messenger
    def pid
      begin
        File.read(Quest.config[:pidfile]).to_i
      rescue
        raise "The quest service isn't running. Use the questctl command to start the service."
      end
    end
    def send_reset
      Process.kill("HUP", pid)
    end
    def send_quit
      Process.kill("QUIT", pid)
    end
    def change_quest(quest)
      File.open(File.join(Quest.config[:state_dir], "active_quest.json"), "w") do |f|
        f.write({"active_quest" => quest}.to_json)
      end
      send_reset
      puts "You are now on the " + Quest.active_quest.cyan + " quest."
    end
  end
end
