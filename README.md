## Quest

Quest-driven learning with RSpec and Serverspec.

### What it is

The quest gem tracks the status of configuration management tasks and provides live feedback.
It supports the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide) content
on the [Puppet Learning VM](https://puppetlabs.com/download-learning-vm).

### How it works

This quest gem is designed to work with the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide),
which is divided into a series of topic-specific chapters, called quests. Each quest contains a series of
tasks that walk the learner through exercises integrated with the chapter's topic. The quest command
provided by this gem allows a user to change the current quest as he or she moves through the content,
and to see live feedback as he or she completes each task in the current quest. The gem also provides
a API that mirrors the functionality of the quest tool, allowing a learner to change quests
and check the status of a quest through a RESTful web interface.

The gem's core is a daemonized process that triggers a set of spec tests a separate
content repository (e.g the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide))
whenever it detects changes in a relevant part of your filesystem. It uses the [filewatcher gem](https://github.com/thomasfl/filewatcher)
to for this filesystem monitoring.

### Installation

From source:

    git clone https://github.com/puppetlabs/quest.git
    cd quest
    gem build quest.gemspec
    gem install quest<VERSION>.gem

### Setup

This gem is designed to work with the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide),
though it will work with any content with the necessary files. It requires a `tests` directory with:

* An `index.json` file consisting of an array of available quest names in an appropriate order.
* A series of `*_spec.rb` files corresponding the the quest names specified in the `index.json`
  file and containing valid Rspec and/or Serverspec tests for that quest.
* A `watch_list.json` containing an array of the directories that the quest tool will watch
  for changes to trigger a run of the spec tests.

### Use

Run the `questctl start` command with the `--quest_dir` parameter to specify
the tests directory of the content repository. The specified directory must contain
the components specified in the **Setup** section above.

    questctl start --quest_dir /usr/src/puppet-quest-guide/tests

Once the questctl process is running, you can use the `quest` command
to view the status of the active quest (`quest status`), list available quests
(`quest list`), or change the active quest (`quest begin <quest_name>`).
