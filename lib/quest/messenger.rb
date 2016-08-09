# -*- encoding : utf-8 -*-
module Quest

  # Shared state and methods for reading from the content directory
  class Messenger

    require 'fileutils'

    attr_reader   :quest_index_file
    attr_reader   :spec_helper
    attr_accessor :active_quest

    def initialize(config = {})
      @task_dir  = config['task_dir']  || Dir.pwd
      validate_task_dir
      @quest_index_file  = File.join(@task_dir, 'index.json')
      @spec_helper       = File.join(@task_dir, 'spec_helper.rb')
      @quest_status = {}
      @active_quest = quests.first
    end

    def set_raw_status(quest, raw_status_hash)
      @quest_status[quest] = raw_status_hash
    end

    def validate_task_dir
      begin
        read_json(@quest_index_file)
      rescue
        puts "No valid quest index.json file found at #{@quest_index_file}"
        exit 1
      end
    end

    def run_setup_command(quest)
      if setup_command(quest)
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

    def quest_spec_path(quest)
      File.join(@task_dir, "#{active_quest}_spec.rb")
    end

    def quests
      read_json(@quest_index_file).keys
    end

    def setup_command
      read_json(@quest_index_file)[active_quest]["setup_command"]
    end

  end
end
