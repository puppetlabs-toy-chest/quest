## Quest

Quest-driven learning with RSpec and Serverspec.

### Description

quest transforms spec tests into an interactive learning system
suitable for configuration management tools and topics.

With quest, you can:

* run tests to check the progress of tasks based on system state.

* monitor the filesystem to trigger tests only as necessary.

* check task status and change the active quest via a CLI and RESTful API.

### Installation

From source:

    git clone https://github.com/puppetlabs/quest.git
    cd quest
    gem build quest.gemspec
    gem install quest<VERSION>.gem

### Use

In the directory containing your quests:

    questctl start

List available quests:

    quest list

Start a quest:

    quest begin <questname>

View quest status

    quest status
