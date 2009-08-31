def grab_files_for(dir)
  basename = File.expand_path(File.dirname(__FILE__))
  dir = File.join(basename, lib, "**", "*.rb")
  basename = File.join(basename, '')
  Dir.glob(dir).each { |file| file.sub(basename, '') }
end

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
  ]
  s.files += grab_files_for("lib")
    + grab_files_for("scripts")
    + grab_files_for("spec")
    + grab_files_for("tasks")
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
