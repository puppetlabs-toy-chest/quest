# -*- encoding : utf-8 -*-
module Quest
  require 'fileutils'


  # Defaults
  @config = {
              :state_dir    => '/usr/local/quest/state',
              :quest_dir    => File.join(Dir.pwd, 'quests'),
              :doc_root     => '/var/www/html/questguide',
              :pidfile      => '/usr/local/quest/pidfile',
              :global_watch => [],
              :quest_watch  => [],
              :active_quest => 'welcome',
            }

  @config_keys = @config.keys

  # Set configuration via hash
  def self.configure(opts = {})
    opts.each { |k,v| @config[k.to_sym] = v if @config_keys.include? k.to_sym}
  end

  # Set configuration via json file
  def self.configure_with(config_path)
    begin
      config = JSON.parse(File.read(config_path))
    rescue Errno::ENOENT
      puts "Configuration file at #{config_path} not found. Using defaults."
      return
    end
    configure(config)
  end

  def self.config
    @config
  end

  def self.check_directory
    quest_index = File.join(@config[:quest_dir], 'index.json')
    unless File.exist?(quest_index)
      raise "#{quest_index} does not exist. Include a valid quest directory in your configuration file, or run this command from a valid quest directory."
    end
  end

  def self.initialize_state_dir
    FileUtils.mkdir_p @config[:state_dir]
  end

  def self.quests
    JSON.parse(File.read(File.join(@config[:quest_dir], 'index.json')))
  end

  def self.active_quest
    JSON.parse(File.read(File.join(@config[:state_dir], 'active_quest.json')))["active_quest"]
  end

  def self.status_raw
    JSON.parse(File.read(File.join(@config[:state_dir], "#{active_quest}.json")))
  end

  def self.status_brief
    s = status_raw
    total = s["summary"]["example_count"]
    complete = total - s["summary"]["failure_count"]
    puts "Quest: " + active_quest.cyan + " - Progress: #{complete} of #{total} Tasks."
  end

  def self.status_brief_nocolor
    s = status_raw
    total = s["summary"]["example_count"]
    complete = total - s["summary"]["failure_count"]
    puts "Quest: " + active_quest + " - Progress: #{complete} of #{total} Tasks."
  end  

  def self.status
    s = status_raw
    puts "Quest: " + "#{active_quest}\n".cyan
    s["examples"].each do |e|
      if e["status"] == "passed"
        puts '√ '.green + e["full_description"]
      else
        puts 'X '.yellow + e["full_description"]
      end
    end
  end

end
