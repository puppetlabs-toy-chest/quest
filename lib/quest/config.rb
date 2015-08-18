module Quest
  require 'fileutils'


  # Defaults
  @config = {
              :state_dir    => '/Users/Henner/Source/quest/spec/fixtures/state',
              :quest_dir    => '/Users/Henner/Source/courseware-lvm/quests',
              :doc_root     => '/tmp',
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

  def self.initialize_directory_structure
    FileUtils.mkdir_p @config[:quest_dir]
    FileUtils.mkdir_p @config[:state_dir]
  end

end
