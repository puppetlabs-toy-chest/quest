module Ballad
  class API < Grape::API
    # Use Grape::API to create RESTful API endpoints for getting quest and task status
    # as JSON and change the active quest.

    def init(state_dir)
      @state_dir = state_dir
      super
    end
    version 'v1', using: :header, vendor: 'puppetlabs'
    format :json

    # These methods are abstracted out to make it easier to move to sqlite
    # or another data storage strategy in the future.
    def get_quest_names_json
      JSON.parse(File.read(File.join(STATE_DIR, 'quests.json')))
    end

    def get_quest_progress_json(quest_name)
      JSON.parse(File.read(File.join(STATE_DIR, "#{quest_name}.json")))
    end

    def get_task_status_json(quest_name, task_number)
      JSON.parse(File.read(File.join(STATE_DIR, 'progress.json')))[quest_name][task_number]
    end

    def post_start_quest(quest_name)
      File.open(File.join(STATE_DIR, "active_quest.json"), "w"){ |f| f.write({'active_quest' => quest_name}.to_json) }
    end

    resource :quests do

      desc "Get quest names"
      get do
        get_quest_names_json
      end

      desc "Get quest progress"
      params do
        requires :quest, type: String, desc: "Quest name"
      end
      route_param :quest do
        get do
          get_quest_progress_json(params[:quest])
        end
      end

      desc "Get task status"
      params do
        requires :quest, type: String, desc: "Quest name"
        requires :task, type: String, desc: "Task number"
      end
      get ":quest/:task" do
        get_task_status_json(params[:quest], params[:task])
      end
    end

    resource :start do

      desc "Start quest"
      post do
        post_start_quest(params[:quest])
        # TODO send a SIGHUP to the quest process
      end

    end

  end
end
