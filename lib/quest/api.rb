module Quest
  class API < Grape::API
    # Use Grape::API to create RESTful API endpoints for getting quest and task status
    # as JSON and change the active quest.

    version 'v1', using: :header, vendor: 'puppetlabs'
    format :json

    helpers do

      include ::Quest::Messenger

      # These methods are abstracted out to make it easier to move to sqlite
      # or another data storage strategy in the future.

      def get_quest_progress_json(quest_name)
        JSON.parse(File.read(File.join(Quest::Messenger::STATE_DIR, "#{quest_name}.json")))
      end

      def get_task_status_json(quest_name, task_number)
        JSON.parse(File.read(File.join(Quest::Messenger::STATE_DIR, 'progress.json')))[quest_name][task_number]
      end

      def post_start_quest(quest_name)
        File.open(File.join(Quest::Messenger::STATE_DIR, "active_quest"), "w"){ |f| f.write(quest_name) }
      end
    end

    resource :quests do

      desc "Get quest names"
      get do
        quests
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
      params do
        requires :quest, type: String, desc: "Quest name"
      end
      route_param :quest do
        post do
          post_start_quest(params[:quest])
          "TEST"
          # TODO send a SIGHUP to the quest process
        end
      end

    end

  end
end
