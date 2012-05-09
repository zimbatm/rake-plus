Gem::Specification.new do |s|
  s.name = "rake-plus"
  s.version = '0.5'
  s.homepage = 'https://github.com/zimbatm/rake-plus'
  s.summary = 'A shiny rake extensions collection'
  s.description = 'A collection of rake extensions that are useful all around'
  s.author = 'Jonas Pfenniger'
  s.email = 'jonas@pfenniger.name'
  s.files = ['README.md'] + Dir['lib/**/*.rb']
  s.require_paths = ["lib"]

  s.add_dependency 'rake'
end
