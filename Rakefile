require 'rake/gempackagetask'
require 'rake/testtask'

task :default => :test

Rake::GemPackageTask.new(eval(File.read('castanaut.gemspec'))) { |g|
  g.need_zip = true
}

Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts = ['-rubygems -I.'] if defined? Gem
end
