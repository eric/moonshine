namespace :local_config do
  after 'deploy:finalize_update', 'local_config:upload'
  after 'deploy:finalize_update', 'local_config:symlink'

  desc <<-DESC
  Uploads local configuration files to the application's shared directory for
  later symlinking (if necessary). Called if local_config is set.
  DESC
  task :upload do
    fetch(:local_config,[]).each do |file|
      filename = File.split(file).last
      if File.exist?( file )
        parent.upload(file, "#{shared_path}/config/#{filename}")
      end
    end
  end

  desc <<-DESC
  Symlinks uploaded local configurations into the release directory.
  DESC
  task :symlink do
    fetch(:local_config,[]).each do |file|
      filename = File.split(file).last
      run "ls #{latest_release}/#{file} 2> /dev/null || ln -nfs #{shared_path}/config/#{filename} #{latest_release}/#{file}"
    end
  end
end

namespace :shared_config do
  after 'moonshine:bootstrap',    'shared_config:upload'
  after 'deploy:finalize_update', 'shared_config:symlink'

  desc <<-DESC
  Uploads local configuration files to the application's shared directory for
  later symlinking (if necessary). Called if shared_config is set.
  DESC
  task :upload do
    fetch(:shared_config, []).each do |file|
      filename = File.split(file).last
      if File.exist?(file)
        put File.read(file), "#{ shared_path }/config/#{ filename }"
      end
    end
  end

  desc <<-DESC
  Downloads remote configuration from the application's shared directory for
  local use.
  DESC
  task :download do
    fetch(:shared_config, []).each do |file|
      filename = File.split(file).last
      if File.exist?(file)
        get "#{ shared_path }/config/#{ filename }", file
      end
    end
  end

  desc <<-DESC
  Symlinks uploaded local configurations into the release directory.
  DESC
  task :symlink do
    fetch(:shared_config, []).each do |file|
      filename = File.split(file).last
      run "ls #{ latest_release }/#{ file } 2> /dev/null || ln -nfs #{ shared_path }/config/#{ filename } #{ latest_release }/#{ file }"
    end
  end
end

