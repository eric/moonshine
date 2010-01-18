
# load the moonshine configuration into
require 'yaml'
begin
  hash = YAML.load_file(File.join((ENV['RAILS_ROOT'] || Dir.pwd), 'config', 'moonshine.yml'))
  hash.each do |key, value|
    set(key.to_sym, value)
  end
rescue Exception
  puts "To use Capistrano with Moonshine, please run 'ruby script/generate moonshine',"
  puts "edit config/moonshine.yml, then re-run capistrano."
  exit(1)
end

namespace :moonshine do
  desc <<-DESC
  Bootstrap a barebones Ubuntu system with Git, Ruby, RubyGems, and Moonshine
  dependencies. Called by deploy:setup.
  DESC
  task :bootstrap do
    moonshine.setup_directories
  end

  desc <<-DESC
  Applies the lib/moonshine_setup_manifest.rb manifest, which replicates the old
  capistrano deploy:setup behavior.
  DESC
  task :setup_directories do
    begin
      config = YAML.load_file(File.join(Dir.pwd, 'config', 'moonshine.yml'))
      put(YAML.dump(config),"/tmp/moonshine.yml")
    rescue Exception => e
      puts e
      puts "Please make sure the settings in moonshine.yml are valid and that the target hostname is correct."
      exit(0)
    end
    upload(File.join(File.dirname(__FILE__), '..', 'lib', 'moonshine_setup_manifest.rb'), "/tmp/moonshine_setup_manifest.rb")
    sudo "shadow_puppet /tmp/moonshine_setup_manifest.rb"
    sudo 'rm -f /tmp/moonshine_setup_manifest.rb /tmp/moonshine.yml'
  end

  desc 'Apply the Moonshine manifest for this application'
  task :apply do
    stage              = ENV['DEPLOY_STAGE'] || fetch(:stage, 'undefined')
    rails_env          = fetch(:rails_env, 'production')
    moonshine_manifest = fetch(:moonshine_manifest, 'application_manifest')

    sudo "env RAILS_ROOT=#{latest_release} DEPLOY_STAGE=#{stage} RAILS_ENV=#{rails_env} shadow_puppet #{latest_release}/app/manifests/#{moonshine_manifest}.rb"
  end

  desc "Update code and then run a console. Useful for debugging deployment."
  task :update_and_console do
    set :moonshine_apply, false
    deploy.update_code
    app.console
  end

  desc "Update code and then run 'rake environment'. Useful for debugging deployment."
  task :update_and_rake do
    rails_env = fetch(:rails_env, 'production')

    set :moonshine_apply, false
    deploy.update_code
    run "cd #{latest_release} && rake --trace RAILS_ENV=#{rails_env} environment"
  end

  before 'deploy:symlink' do
    apply if fetch(:moonshine_apply, true) == true
  end
end
