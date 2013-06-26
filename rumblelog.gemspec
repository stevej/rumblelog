Gem::Specification.new do |s|
  s.name        = 'rumblelog'
  s.version     = '0.1.0'
  s.date        = '2013-06-25'
  s.summary     = "A site publishing system!"
  s.description = "A dynamic site publishing with Pages and Tags"
  s.license     = "Apache 2.0"
  s.authors     = ["Steve Jenson"]
  s.email       = 'stevej@fruitless.org'
  s.homepage    =
    'http://github.com/stevej/rumblelog'

  s.files         = `git ls-files`.split($/)
  s.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler"
  s.add_dependency "sinatra"
  s.add_dependency "fauna"
end
