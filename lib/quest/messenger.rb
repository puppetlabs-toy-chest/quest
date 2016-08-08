# -*- encoding : utf-8 -*-
module Quest

  class Messenger

    require 'fileutils'

    attr_reader :state_dir
    attr_reader :pidfile
    attr_reader :task_dir
    attr_reader :active_quest_file
    attr_reader :status_line_file
    attr_reader :quest_index_file
    attr_reader :spec_helper

    def initialize(config = {})
      @state_dir = config['state_dir'] || '/var/opt/quest'
      @pidfile   = config['pidfile']   || '/var/run/quest.pid'
      @task_dir  = config['task_dir']
      @active_quest_file = File.join(@state_dir, 'active_quest')
      @status_line_file  = File.join(@state_dir, 'active_quest_status')
      @quest_lock        = File.join(@state_dir, 'quest.lock')
      @quest_index_file  = File.join(@task_dir, 'index.json')
      @spec_helper       = File.join(@taks_dir, 'spec_helper.rb')
    end

    def validate_task_dir
      begin
        read_json(@quest_index_file)
      rescue
        puts "No valid quest index.json file found at #{@quest_index_file}"
        exit 1
      end
    end

    def set_active_quest(quest)
      File.open(@active_quest_file, 'w') do |f|
        f.write(quest)
      end
      run_setup_command
    end

    def run_setup_command
      if setup_command
        begin
          puts "Setting up the #{active_quest} quest..."
          Dir.chdir(@task_dir){
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
      FileUtils.touch(@quest_lock)
    end

    def release_lock
      File.delete(@quest_lock)
    end

    def lock_on?
      File.exist?(@quest_lock)
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
      FileUtils.mkdir_p @state_dir
    end

    def read_json(path)
      JSON.parse(File.read(path))
    end

    def active_quest_spec_path
      File.join(@task_dir, "#{active_quest}_spec.rb")
    end

    def quests
      read_json(@quest_index_file).keys
    end

    def active_quest
      set_first_quest unless File.exists?(@active_quest_file)
      File.read(@active_quest_file)
    end

    def active_quest_json_output_path
      File.join(@state_dir, "#{active_quest}.json")
    end

    def status_line_output_path
      File.join(@state_dir, "active_quest_status")
    end

    def quest_watch
      read_json(@quest_index_file)[active_quest]["watch_list"]
    end

    def setup_command
      read_json(@quest_index_file)[active_quest]["setup_command"]
    end

    def raw_status
      read_json(File.join(@state_dir, "#{active_quest}.json"))
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
        File.read(@pidfile).to_i
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
