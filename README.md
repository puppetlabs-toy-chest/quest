## Quest

Quest-driven learning with RSpec and Serverspec.

### Description

quest transforms Markdown content and Serverspec tests into an interactive
learning system suitable for configuration management tools and topics.

With quest, you can:

* build a static HTML guide from Markdown source.

* run tests to check the progress of tasks based on system state.

* monitor the filesystem to trigger tests only as necessary.

* check task status and change the active quest via a CLI and RESTful API.

### Installation

From rubygems.org (pending publishing!):

    gem install quest

From source:

    git clone https://github.com/puppetlabs/quest.git
    cd quest
    gem build quest.gemspec
    gem install quest-0.0.1.gem

### Use

In the directory containing your quests (see the [Learning VM content](https://github.com/puppetlabs/courseware-lvm/tree/quests-only)
for an example):

    questctl build
    questctl start

Note that you must set up your own server to make the quest content available.
The default document root that questctl builds to is /var/www/html/questguide/

List available quests:

    quest list

Start a quest:

    quest begin <questname>

View quest status

    quest status
