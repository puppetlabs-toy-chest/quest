# -*- encoding : utf-8 -*-
module Quest

  module Messenger

    require 'fileutils'

    STATE_DIR = config['state_dir'] || '/var/opt/quest'
    PIDFILE   = config['pidfile']   || '/var/run/quest.pid'
    TASK_DIR  = config['task_dir']  || Dir.pwd

    ACTIVE_QUEST_FILE = File.join(STATE_DIR, 'active_quest')
    STATUS_LINE_FILE  = File.join(STATE_DIR, "active_quest_status")
    QUEST_LOCK        = File.join(STATE_DIR, "quest.lock")
    QUEST_INDEX_FILE  = File.join(TASK_DIR, 'index.json')
    SPEC_HELPER       = File.join(TAKS_DIR, 'spec_helper.rb')

    def validate_quest_dir
      begin
        read_json(QUEST_INDEX_FILE)
      rescue
        puts "No valid quest index.json file found at #{QUEST_INDEX_FILE}"
        exit 1
      end
    end

    def set_active_quest(quest)
      File.open(ACTIVE_QUEST_FILE, 'w') do |f|
        f.write(quest)
      end
      run_setup_command
    end

    def run_setup_command
      if setup_command
        begin
          puts "Setting up the #{active_quest} quest..."
          Dir.chdir(TASK_DIR){
            setup_io = IO.popen(setup_command) do |io|
              io.each do |line|
                puts line
              end
            end
          }
        rescue
          puts "Setup for #{active_quest} failed"
        end
      end
    end

    def set_lock
      FileUtils.touch(QUEST_LOCK)
    end

    def release_lock
      File.delete(QUEST_LOCK)
    end

    def lock_on?
      File.exist?(QUEST_LOCK)
    end

    def offer_bailout(message)
      print "#{message} Continue? [Y/n]:"
      raise "Cancelled" unless [ 'y', 'yes', ''].include? STDIN.gets.strip.downcase
    end

    def active_quest_complete?
      raw_status["summary"]["failure_count"] == 0
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

    def active_quest_spec_path
      File.join(TASK_DIR, "#{active_quest}_spec.rb")
    end

    def quests
      read_json(QUEST_INDEX_FILE).keys
    end

    def active_quest
      set_first_quest unless File.exists?(ACTIVE_QUEST_FILE)
      File.read(ACTIVE_QUEST_FILE)
    end

    def active_quest_json_output_path
      File.join(STATE_DIR, "#{active_quest}.json")
    end

    def status_line_output_path
      File.join(STATE_DIR, "active_quest_status")
    end

    def quest_watch
      read_json(QUEST_INDEX_FILE)[active_quest]["watch_list"]
    end

    def setup_command
      read_json(QUEST_INDEX_FILE)[active_quest]["setup_command"]
    end

    def raw_status
      read_json(File.join(STATE_DIR, "#{active_quest}.json"))
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
