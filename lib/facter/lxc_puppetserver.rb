Facter.add('lxc_puppetserver') do
  setcode do
    Puppet[:server]
  end
end
