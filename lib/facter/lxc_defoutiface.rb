Facter.add('lxc_defoutiface') do
  setcode do
    iface = nil
    ipaddress = Facter.value(:ipaddress)
    Facter.value(:interfaces).split(',').each { |test_iface|
      iface = test_iface if Facter.value("ipaddress_#{test_iface}") == ipaddress
    } unless ipaddress.nil?
    iface
  end
end
