desc "Run the specs under spec with code coverage by rcov"
task :rcov do
 `rcov -i "^lib" -x ".*" spec/*.rb`
end