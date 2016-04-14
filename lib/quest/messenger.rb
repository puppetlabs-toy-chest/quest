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
        puts "No valid quest index.json file found in #{path}. Run this command from a directory containing such a file, or specify one with the --quest_dir flag."
        exit 1
      end
    end

    def set_active_quest(quest)
      File.open(File.join(STATE_DIR, 'active_quest'), 'w') do |f|
        f.write(quest)
      end
      run_setup_command
    end

    def run_setup_command
      if setup_command
        begin
          Dir.chdir(quest_dir){`#{setup_command}`}
        rescue
          puts "Setup for #{active_quest} failed"
        end
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

    def spec_helper
      File.join(quest_dir, 'spec_helper.rb')
    end

    def spec_file
      File.join(quest_dir, "#{active_quest}_spec.rb")
    end

    def quests
      read_json(File.join(quest_dir, 'index.json')).keys
    end

    def active_quest
      File.read(File.join(STATE_DIR, 'active_quest'))
    end

    def json_output_file
      File.join(STATE_DIR, "#{active_quest}.json")
    end

    def status_line_output_file
      File.join(STATE_DIR, "active_quest_status")
    end

    def quest_watch
      read_json(File.join(quest_dir, "index.json"))[active_quest]["watch_list"]
    end

    def setup_command
      read_json(File.join(quest_dir, "index.json"))[active_quest]["setup_command"]
    end

    def raw_status
      JSON.parse(File.read(File.join(STATE_DIR, "#{active_quest}.json")))
    end

    def status( options = {:brief => false, :color => true, :raw => false } )
      return raw_status if options[:raw]

      quest_name = options[:color] ? active_quest.cyan : active_quest

      output = "Quest: " + quest_name

      if options[:brief]
        total = raw_status["summary"]["example_count"]
        complete = total - raw_status["summary"]["failure_count"]
        output << " - Progress: #{complete} of #{total} Tasks."
      else
        # Add line break after quest name for full output
        output << "\n"
        raw_status["examples"].each do |example|
          if example["status"] == "passed"
            output << '√ '.green
          else
            output << 'X '.yellow
          end
          output << example["full_description"] + "\n"
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
