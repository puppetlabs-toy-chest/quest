# -*- encoding : utf-8 -*-
module Quest

  module Messenger

    require 'fileutils'

    STATE_DIR = '/var/opt/quest'
    PIDFILE = '/var/run/quest.pid'

    def set_state(opts={})
      quest_dir = opts[:quest_dir] || File.join(Dir.pwd, 'quests')
      {
        'quest_dir' => quest_dir,
        'quests'    => read_json(File.join(quest_dir, 'index.json'))
      }
    end

    def save_state(opts={})
      File.open(File.join(STATE_DIR, 'state.json'), 'w') do |f|
        f.write(set_state(opts).to_json)
      end
    end

    def validate_quest_dir(path)
      begin
        read_json(File.join(path, 'index.json'))
      rescue
        raise "No quest index.json file found in #{path}. Run this command from a directory containing such a file, or specify one with the --quest_dir flag."
      end
    end

    def set_active_quest(quest)
      File.open(File.join(STATE_DIR, 'active_quest'), 'w') do |f|
        f.write(quest)
      end
    end

    def set_first_quest
      first_quest = quests.first
      set_active_quest(first_quest)
    end

    def initialize_state_dir
      FileUtils.mkdir_p STATE_DIR
    end

    def read_json(path)
      JSON.parse(File.read(path))
    end

    def get_state_hash
      read_json(File.join(STATE_DIR, 'state.json'))
    end

    def quest_dir
      get_state_hash['quest_dir']
    end

    def quests
      read_json(File.join(quest_dir, 'index.json'))
    end

    def active_quest
      File.read(File.join(STATE_DIR, 'active_quest'))
    end

    def get_quest_config_hash
      read_json(File.join(quest_dir, active_quest, 'config.json'))
    end

    def quest_watch
      get_quest_config_hash['quest_watch']
    end

    def status( options = {:brief => false, :color => true, :raw => false } )
      # Parse the Raw status
      s = JSON.parse(File.read(File.join(STATE_DIR, "#{active_quest}.json")))

      if options[:color] then
        quest_name = active_quest.cyan
      else
        quest_name = active_quest
      end

      if options[:raw] then
        output = s
      else
        output = "Quest: " + quest_name
      end

      if options[:brief] then
        total = s["summary"]["example_count"]
        complete = total - s["summary"]["failure_count"]
        output.append " - Progress: #{complete} of #{total} Tasks."
      else
        s["examples"].each do |e|
          if e["status"] == "passed"
            output.append '√ '.green + e["full_description"]
          else
            output.append 'X '.yellow + e["full_description"]
          end
        end
      end  

      output
    end

    def pid
      begin
        File.read(PIDFILE).to_i
      rescue
        puts "The quest service isn't running. Use the questctl command to start the service."
        raise
      end
    end

    def send_reset
      Process.kill("HUP", pid)
    end

    def send_quit
      Process.kill("QUIT", pid)
    end

    def change_quest(quest)
      set_active_quest(quest)
      send_reset
      puts "You are now on the " + active_quest.cyan + " quest."
    end

  end
end
