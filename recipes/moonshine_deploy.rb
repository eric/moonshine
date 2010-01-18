set :branch, 'master'
set :scm, :git
set :git_enable_submodules, 1
ssh_options[:paranoid] = false
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
set :keep_releases, 2

set :scm, :svn if !! repository =~ /^svn/

after 'deploy:restart', 'deploy:cleanup'

namespace :deploy do
  desc "Restart the Passenger processes on the app server by touching tmp/restart.txt."
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with Passenger"
    task t, :roles => :app do ; end
  end

  desc <<-DESC
    Prepares one or more servers for deployment. Before you can use any \
    of the Capistrano deployment tasks with your project, you will need to \
    make sure all of your servers have been prepared with `cap deploy:setup'. When \
    you add a new server to your cluster, you can easily run the setup task \
    on just that server by specifying the HOSTS environment variable:

      $ cap HOSTS=new.server.com deploy:setup

    It is safe to run this task on servers that have already been set up; it \
    will not destroy any deployed revisions or data.
  DESC
  task :setup, :except => { :no_release => true } do
    moonshine.bootstrap
  end
end

namespace :apache do
  desc "Restarts the Apache web server"
  task :restart do
    sudo 'service apache2 restart'
  end
end

namespace :vcs do
  before 'moonshine:bootstrap', 'vcs:install'

  desc "Installs the scm"
  task :install do
    package = case fetch(:scm).to_s
      when 'svn' then 'subversion'
      when 'git' then 'git-core'
      else scm.to_s
    end
    sudo "apt-get -qq -y install #{package}" unless package == 'none'
  end
end
