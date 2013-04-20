require 'ipaddr'

# Util module for iksteen-lxc
module Puppet::Parser::Functions
  # Convert cidr to netmask
  newfunction(:is_ip_in_range, :type => :rvalue) do |args|
    IPAddr.new(args[0] + '/' + args[1]).include?(IPAddr.new(args[2]))
  end
end
