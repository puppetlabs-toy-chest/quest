require 'rack'
require 'grape'
require 'filewatcher'
require 'json'
require_relative './test'

STATUS_DIR = File.join(Dir.pwd, 'status')

module Quest
  class API < Grape::API
    version 'v1', using: :header, vendor: 'puppetlabs'
    format :json

    resource :quests do

      desc "Get quest names"
      get do
        JSON.parse(File.read(File.join(STATUS_DIR, 'quests.json')))
      end

      desc "Get quest progress"
      params do
        requires :quest, type: String, desc: "Quest name"
      end
      route_param :quest do
        get do
          JSON.parse(File.read(File.join(STATUS_DIR, 'progress.json')))[params[:quest]]
        end
      end

      desc "Get task status"
      params do
        requires :quest, type: String, desc: "Quest name"
        requires :task, type: String, desc: "Task number"
      end
      get ":quest/:task" do
        JSON.parse(File.read(File.join(STATUS_DIR, 'progress.json')))[params[:quest]][params[:task]]
      end
    end

  end
end

fork do
  Rack::Handler::WEBrick.run Quest::API
end

FileWatcher.new(["./watch"]).watch do |f|
end
