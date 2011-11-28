# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tdoc}
  s.version = "0.5.0"
  s.summary = %q{Test oriented documentation}
  s.description = %q{Combines Test::Unit, Shoulda, and Rdoc to embed tests inside documentation }
  s.authors     = ["Herb Daily"]
  s.email       = 'herb.daily@safe-mail.net'
  s.homepage    = 'http://github.com/herbdaily/tdoc'
  s.required_rubygems_version = Gem::Requirement.new(">= 1.0.0") if s.respond_to? :required_rubygems_version=
  s.add_runtime_dependency 'shoulda', '~>2.11.3'
  s.files = ['README.rdoc','bin/tdoc.rb']
  s.executables = ["tdoc.rb"]
  s.default_executable = "tdoc.rb"
end
