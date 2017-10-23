namespace :outdated do
  namespace "admin-ui" do
    desc "List outdated admin-ui Bower dependencies"
    task :bower do
      require "childprocess"
      process = ChildProcess.build("./node_modules/.bin/bower", "list")
      process.cwd = File.join(API_UMBRELLA_SRC_ROOT, "src/api-umbrella/admin-ui")
      process.io.inherit!
      process.start
      process.wait
    end

    desc "List outdated admin-ui NPM dependencies"
    task :npm do
      require "childprocess"
      process = ChildProcess.build("yarn", "outdated")
      process.cwd = File.join(API_UMBRELLA_SRC_ROOT, "src/api-umbrella/admin-ui")
      process.io.inherit!
      process.start
      process.wait
    end
  end

  namespace "test" do
    desc "List outdated test gem dependencies"
    task :gems do
      require "childprocess"
      Bundler.with_original_env do
        process = ChildProcess.build("bundle", "outdated")
        process.cwd = API_UMBRELLA_SRC_ROOT
        process.io.inherit!
        process.start
        process.wait
      end
    end
  end

  desc "List outdated package dependencies"
  task :packages do
    require_relative "./outdated_packages"
    OutdatedPackages.new
  end
end

desc "List outdated dependencies"
task :outdated do
  puts "==== ADMIN-UI: NPM ===="
  Rake::Task["outdated:admin-ui:npm"].invoke
  puts "\n\n"

  puts "==== ADMIN-UI: BOWER ===="
  Rake::Task["outdated:admin-ui:bower"].invoke
  puts "\n\n"

  puts "==== TEST: GEMS ===="
  Rake::Task["outdated:test:gems"].invoke
  puts "\n\n"

  puts "==== PACKAGES ===="
  Rake::Task["outdated:packages"].invoke
end
