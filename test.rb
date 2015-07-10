require 'serverspec'
require 'yaml'

module Quest

  class Tester
  
    include Serverspec::Helper::Exec
    include Serverspec::Helper::DetectOS

    def initialize(quest_dir, status_dir)
      @quest_dir = quest_dir
      @status_dir = status_dir
    end
    
    Spec.configure do |c|
      c.output_stream = File.open('/dev/null', 'w')
      c.add_formatter(:json)
      if ENV['ASK_SUDO_PASSWORD']
        require 'highline/import'
        c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
      else
        c.sudo_password = ENV['SUDO_PASSWORD']
      end
    end
    
    config = RSpec.configuration
    json_formatter = RSpec::Core::Formatters::JsonFormatter.new(config.out)
    reporter  = RSpec::Core::Reporter.new(json_formatter)
    config.instance_variable_set(:@reporter, reporter)
    
    def run(quest)
      RSpec::Core::Runner.run(File.join(@quest_dir), "#{quest}_spec.rb")
      File.open(@status_dir, "w"){ |f| f.write(json_formatter.output_hash) }
    end

  end
  
end
