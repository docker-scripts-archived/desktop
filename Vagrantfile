# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'ltsp/linuxmint-19-xfce-32bit'

  config.vm.network 'forwarded_port', guest: 80, host: 80
  config.vm.network 'forwarded_port', guest: 5900, host: 5900
  config.vm.network 'forwarded_port', guest: 6901, host: 6901

  config.vm.provider 'virtualbox' do |virtualbox|
    virtualbox.gui = true
    virtualbox.memory = 1024
    virtualbox.name = 'WebVNC'
  end

  config.vm.provision 'shell', path: 'install.sh'
end

