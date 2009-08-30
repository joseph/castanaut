Gem::Specification.new do |s|
  s.name = %q{castanaut}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joseph Pearson"]
  s.date = %q{2008-09-10}
  s.default_executable = %q{castanaut}
  s.description = %q{Automate your screencasts.}
  s.email = ["joseph@inventivelabs.com.au"]
  s.executables = ["castanaut"]
  s.extra_rdoc_files = ["Copyright.txt", "History.txt", "Manifest.txt", "README.txt"]
  s.files = [
    "Copyright.txt",
    "History.txt",
    "Manifest.txt",
    "README.txt",
    "Rakefile",
    "bin/castanaut",
    "cbin/osxautomation",
    "lib/castanaut.rb",
    "lib/castanaut/exceptions.rb",
    "lib/castanaut/ext/string.rb",
    "lib/castanaut/keys.rb",
    "lib/castanaut/main.rb",
    "lib/castanaut/movie.rb",
    "lib/castanaut/plugin.rb",
    "lib/plugins/ishowu.rb",
    "lib/plugins/keystack.rb",
    "lib/plugins/mousepose.rb",
    "lib/plugins/safari.rb",
    "lib/plugins/snapz_pro.rb",
    "lib/plugins/terminal.rb",
    "lib/plugins/textmate.rb",
    "scripts/coords.js",
    "scripts/gebys.js",
    "spec/castanaut_spec.rb",
    "spec/spec_helper.rb",
    "tasks/ann.rake",
    "tasks/annotations.rake",
    "tasks/doc.rake",
    "tasks/gem.rake",
    "tasks/manifest.rake",
    "tasks/post_load.rake",
    "tasks/rubyforge.rake",
    "tasks/setup.rb",
    "tasks/spec.rake",
    "tasks/svn.rake"]
  s.has_rdoc = true
  s.homepage = %q{http://castanaut.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{castanaut}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Automate your screencasts.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
