module Quest

  class QuestGuide
    require 'liquid'
    require 'redcarpet'
    require 'erb'
    require 'fileutils'

    def initialize
      @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
      @quests = JSON.parse(File.read(File.join(Quest.config[:quest_dir], 'index.json')))
    end

    def load_erb(template)
      ERB.new(File.read(File.expand_path("../../../erb/#{template}.erb", __FILE__)), nil, '-')
    end

    def parse_quest_content(quest)
      File.open(File.join(Quest.config[:quest_dir], quest, "#{quest}.md"), "r") do |f|
        @markdown.render(f.read)
      end
    end

    def generate_quest_html(quest)
      @quest = quest
      ["header", "footer", "sidebar"].each do |template|
        instance_variable_set("@#{template}", load_erb(template).result(binding))
      end
      @content = parse_quest_content(quest)
      File.open(File.join(Quest.config[:doc_root], "#{quest}.html"), "w") do |f|
        f.write(load_erb("quest").result(binding))
      end
    end

    def place_web_files(quest)
      asset_src = File.join(Quest.config[:quest_dir], quest, "assets")
      asset_dest = File.join(Quest.config[:doc_root], "public/assets")
      begin
        FileUtils.cp_r(asset_src, asset_dest)
      rescue Errno::ENOENT
      end
      #public_src = File.join(Quest.config[:quest_dir], "public")
      #public_dest = Quest.config[:doc_root]
    end

    def quest_url(quest)
      File.join(Quest.config[:doc_root], "#{quest}.html")
    end

    def populate_web_dir
      ["public", "public/js", "public/css", "public/assets", "public/fonts"].each do |d|
        begin
          Dir.mkdir(File.join(Quest.config[:doc_root], d))
        rescue Errno::EEXIST
        end
      end
      @quests.each do |q|
        place_web_files(q)
        generate_quest_html(q)
      end
    end

  end
end
