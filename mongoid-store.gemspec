# encoding: UTF-8
require File.expand_path('../lib/mongoid-store/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = "mongoid-store"
  s.version      = MongoidStore::Version
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Ara Howard"]
  s.email        = ["ara.t.howard@gmail.com"]
  s.homepage     = "http://github.com/ahoward/mongoid-store"
  s.description  = "Rails Mongoid 3 Cache store."
  s.summary      = "Rails Mongoid 3 Cache store"
  s.license      = "Same as Ruby's"

  s.add_dependency 'mongoid',       '>= 6'
  s.add_dependency 'activesupport', '>= 5'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
