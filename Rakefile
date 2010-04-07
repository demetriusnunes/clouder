require 'hoe'

Hoe.spec('clouder') do
  developer 'Demetrius Nunes', 'demetriusnunes@gmail.com'
  extra_deps << [ 'rest-client', '>= 0' ]
  extra_deps << [ 'json', '>= 0' ]
end

Dir['tasks/**/*.rake'].each { |t| load t }

task :default => :spec