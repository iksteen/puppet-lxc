require 'ipaddr'

# Util module for iksteen-lxc
module Puppet::Parser::Functions
  # Convert cidr to netmask
  newfunction(:cidr_to_netmask, :type => :rvalue) do |args|
    IPAddr.new('255.255.255.255').mask(args[0]).to_s
  end
end
