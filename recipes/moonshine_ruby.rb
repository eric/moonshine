
namespace :ruby do
  before 'moonshine:bootstrap', 'ruby:install'

  desc "Forces a reinstall of Ruby and restarts Apache/Passenger"
  task :upgrade do
    install
    apache.restart
  end

  desc "Install Ruby + Rubygems"
  task :install do
    install_deps
    send fetch(:ruby, 'ree').intern
    install_rubygems
    install_moonshine_deps
  end

  task :mri do
    apt
  end

  task :apt do
    sudo "apt-get install -q -y ruby-full"
  end

  task :remove_ruby_from_apt do
    sudo "apt-get remove -q -y ^.*ruby.* || true"
    #TODO apt-pinning to ensure ruby is never installed via apt
  end

  task :ree do
    remove_ruby_from_apt
    run [
      'cd /tmp',
      'rm -rf ruby-enterprise-1.8.6-20090610* || true',
      'wget -q http://assets.railsmachine.com/other/ruby-enterprise-1.8.6-20090610.tar.gz',
      'tar xzf ruby-enterprise-1.8.6-20090610.tar.gz',
      'sudo /tmp/ruby-enterprise-1.8.6-20090610/installer --dont-install-useful-gems -a /usr'
    ].join(" && ")
  end

  task :ree187 do
    remove_ruby_from_apt
    run [
      'cd /tmp',
      'rm -rf ruby-enterprise-1.8.7-2009.10.tar.gz* || true',
      'wget -q http://rubyforge.org/frs/download.php/66162/ruby-enterprise-1.8.7-2009.10.tar.gz',
      'tar xzf ruby-enterprise-1.8.7-2009.10.tar.gz',
      'sudo /tmp/ruby-enterprise-1.8.7-2009.10/installer --dont-install-useful-gems -a /usr'
    ].join(" && ")
  end

  task :src187 do
    remove_ruby_from_apt
    run [
      'cd /tmp',
      'rm -rf ruby-1.8.7-p174* || true',
      'wget -q ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p174.tar.bz2',
      'tar xjf ruby-1.8.7-p174.tar.bz2',
      'cd /tmp/ruby-1.8.7-p174',
      './configure --prefix=/usr',
      'make',
      'sudo make install'
    ].join(" && ")
  end

  task :install_rubygems do
    run [
      'cd /tmp',
      'rm -rf rubygems-1.3.5* || true',
      'wget -q http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz',
      'tar xfz rubygems-1.3.5.tgz',
      'cd /tmp/rubygems-1.3.5',
      'sudo ruby setup.rb',
      'sudo ln -s /usr/bin/gem1.8 /usr/bin/gem || true',
      'gem update --system'
    ].join(" && ")
  end

  task :install_deps do
    sudo "apt-get update"
    sudo "apt-get install -q -y build-essential zlib1g-dev libssl-dev libreadline5-dev wget"
  end

  task :install_moonshine_deps do
    sudo "gem install rake --no-rdoc --no-ri"
    sudo "gem install puppet -v 0.24.8 --no-rdoc --no-ri"
    sudo "gem install shadow_puppet --no-rdoc --no-ri"
  end
end
