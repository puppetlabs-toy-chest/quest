## Quest

Quest-driven learning with RSpec and Serverspec.

### What it is

The quest gem provides a learner with live feedback as a learner progresses through
a series of configuration management tasks defined by RSpec tests.
It was designed to support the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide)
content on the [Puppet Learning VM](https://puppetlabs.com/download-learning-vm), but can be
used for any project with a compatible format.

### Installation

From source:

    git clone https://github.com/puppetlabs/quest.git
    cd quest
    gem build quest.gemspec
    gem install quest<VERSION>.gem

### Setup

This gem was designed to support the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide),
and works with any set of tests and metadata following the same pattern.

Any project you wish to use with this tool must contain a directory with the following contents:

An `index.json` file consisting of an array of available quest names in an appropriate order.

```
[
  "my_first_quest",
  "my_second_quest"
]
```

A series of `*_spec.rb` files corresponding the the quest names specified in the `index.json`.
These files must contain valid Rspec tests that correspond to the tasks in that quest. For example,
`my_first_quest_spec.rb` might contain the following. (Note the callous abuse of the RSpec format to
coerce its output into something appropriate to the quest tool interface.)

```
describe "Task 1: do
  it 'create a user named test' do
    file('/etc/passwd').should contain "test"
  end
end
describe "Task 2: do
 ...
end
```

A `spec_helper` file with any required libraries, helper functions, or variables
needed by the tests.

```
require 'serverspec'
require 'pathname'

PROD_PATH = '/etc/puppetlabs/code/environments/production'
MODULE_PATH = PROD_PATH + "modules/"
```

A `watch_list.json` containing an array of the directories that the quest tool will watch
for changes to trigger a run of the spec tests. As a minimal example, you can configure your
bash prompt to write to bash_history at each shell prompt and run on changes to bash_history.

```
[
  "/root/.bash_history"
]
```

### Use

Run the `questctl start` command with the `--quest_dir` parameter to specify
the tests directory of the content repository. The specified directory must contain
the components specified in the **Setup** section above.

    questctl start --quest_dir /usr/src/puppet-quest-guide/tests

Once the questctl process is running, you can use the `quest` command
to view the status of the active quest (`quest status`), list available quests
(`quest list`), or change the active quest (`quest begin <quest_name>`).

### How it works

The quest command provided by this gem allows a user to change the current quest as he or she moves
through the content, and to see live feedback as he or she completes each task in the current quest.
The gem also provides a API that mirrors the functionality of the quest tool, allowing a learner to
change quests and check the status of a quest through a RESTful web interface.

The gem's core is a daemonized process that triggers a set of spec tests a separate
content repository (e.g the [Puppet Quest Guide](https://github.com/puppetlabs/puppet-quest-guide))
whenever it detects changes in a relevant part of your filesystem. It uses the [filewatcher gem](https://github.com/thomasfl/filewatcher)
for this filesystem monitoring.
