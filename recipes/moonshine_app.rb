namespace :app do
  namespace :symlinks do
    after 'deploy:finalize_update', 'app:symlinks:update'

    desc <<-DESC
    Link public directories to shared location.
    DESC
    task :update, :roles => [:app, :web] do
      fetch(:app_symlinks, []).each { |link| run "ln -nfs #{shared_path}/public/#{link} #{latest_release}/public/#{link}" }
    end
  end

  desc "remotely console"
  task :console, :roles => :app, :except => {:no_symlink => true} do
    input = ''
    run "cd #{current_path} && ./script/console #{fetch(:rails_env, "production")}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end

  desc "Show requests per second"
  task :rps, :roles => :app, :except => {:no_symlink => true} do
    count = 0
    last = Time.now
    run "tail -f #{shared_path}/log/#{fetch(:rails_env, "production")}.log" do |ch, stream, out|
      break if stream == :err
      count += 1 if out =~ /^Completed in/
      if Time.now - last >= 1
        puts "#{ch[:host]}: %2d Requests / Second" % count
        count = 0
        last = Time.now
      end
    end
  end

  desc "tail application log file"
  task :log, :roles => :app, :except => {:no_symlink => true} do
    run "tail -f #{shared_path}/log/#{fetch(:rails_env, "production")}.log" do |channel, stream, data|
      puts "#{data}"
      break if stream == :err
    end
  end

  desc "tail vmstat"
  task :vmstat, :roles => [:web, :db] do
    run "vmstat 5" do |channel, stream, data|
      puts "[#{channel[:host]}]"
      puts data.gsub(/\s+/, "\t")
      break if stream == :err
    end
  end
end
