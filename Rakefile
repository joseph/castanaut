# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'castanaut'

task :default => 'spec:run'

PROJ.name = 'castanaut'
PROJ.authors = 'Joseph Pearson'
PROJ.email = 'joseph@inventivelabs.com.au'
PROJ.url = 'http://castanaut.rubyforge.org'
PROJ.version = Castanaut::VERSION

PROJ.rubyforge_name = 'castanaut'
PROJ.rdoc_remote_dir = 'doc'

PROJ.exclude += ['^spec\/*', '^test\/*']

PROJ.spec_opts << '--color'

# EOF
