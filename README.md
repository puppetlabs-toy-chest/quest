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

An `index.json` file consisting with available quest names, the list of files to watch for each quest
and an optional setup command for that quest. These setup commands will be run with the directory
of your tests as the current working directory when a user begins the quest.

```
{
  "welcome": {
    "setup_command": "puppet apply ./manifests/welcome.pp"
  }
}
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

### Use

The `questctl` command is used to start the quest service. Run it from the
task directory, or use the `--task_dir` flag.

'''
/usr/local/bin/questctl start --task_dir /usr/src/puppet-quest-guide/tests
'''

This works best when the service is managed by an init system, for example:

'''
# /etc/systemd/system/quest.service
[Unit]
Description=Quest tool service

[Service]
ExecStart=/usr/local/bin/questctl start --task_dir /usr/src/puppet-quest-guide/tests

[Install]
WantedBy=multi-user.target
'''

### How it works

The quest service runs a set of RSpec tests for the current test in a loop,
updating the quest status each time the test completes. The service provides
api endpoints on port 4567 that allow access to the RSpec output and a POST
endpoint to change the current quest.

The `quest` command is a wrapper for these API endpoints.

