$:.unshift('lib')  unless $:.include?('lib')

require 'castanaut'

spec = Gem::Specification.new do |s|
  s.name = 'castanaut'
  s.version = Castanaut::VERSION
  s.summary = "Castanaut - automate your screencasts"
  s.description = "Castanaut lets you write executable scripts for screencasts."
  s.author = "Joseph Pearson"
  s.email = "joseph@inventivelabs.com.au"
  s.homepage = "http://gadgets.inventivelabs.com.au/castanaut"
  s.rubyforge_project = "nowarning"
  s.files = Dir['*.md'] +
    Dir['bin/*'] +
    Dir['cbin/*'] +
    Dir['lib/**/*.rb'] +
    Dir['scripts/**/*.js'] +
    Dir['test/**/*.rb']
  s.executables = ["castanaut"]
  s.require_path = 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = Dir['*.md']
  s.rdoc_options += [
    '--title', 'Castanaut',
    '--main', 'README.md'
  ]
  s.add_development_dependency("rake")
end
