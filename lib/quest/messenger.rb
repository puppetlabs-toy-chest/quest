module Quest
  module Messenger
    def pid
      File.read(Quest.config[:pidfile]).to_i
    end
    def send_reset
      Process.kill("HUP", pid)
    end
    def change_quest(quest)
      File.open(File.join(Quest.config[:state_dir], "active_quest.json"), "w") do |f|
        f.write({"active_quest" => quest}.to_json)
      end
      send_reset
    end
  end
end
