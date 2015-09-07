# -*- encoding : utf-8 -*-
module Ballad
  class API < Grape::API

    def init(state_dir)
      @state_dir = state_dir
      super
    end
    version 'v1', using: :header, vendor: 'puppetlabs'
    format :json

    resource :quests do

      desc "Get quest names"
      get do
        JSON.parse(File.read(File.join(STATE_DIR, 'quests.json')))
      end

      desc "Get quest progress"
      params do
        requires :quest, type: String, desc: "Quest name"
      end
      route_param :quest do
        get do
          JSON.parse(File.read(File.join(STATE_DIR, "#{params[:quest]}.json")))
        end
      end

      desc "Get task status"
      params do
        requires :quest, type: String, desc: "Quest name"
        requires :task, type: String, desc: "Task number"
      end
      get ":quest/:task" do
        JSON.parse(File.read(File.join(STATE_DIR, 'progress.json')))[params[:quest]][params[:task]]
      end
    end

    resource :start do

      desc "Start quest"
      post do
        File.open(File.join(STATE_DIR, "active_quest.json"), "w"){ |f| f.write({'active_quest' => params[:quest]}.to_json) }
      end

    end

  end
end
