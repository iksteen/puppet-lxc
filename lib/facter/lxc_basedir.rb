Facter.add('lxc_basedir') do
  setcode do
    File.join(Puppet[:vardir], 'lxc')
  end
end
