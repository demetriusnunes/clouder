desc "Run the test server"
task :server do
  `rackup spec/config.ru`
end