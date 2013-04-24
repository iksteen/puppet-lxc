lxc
===

This module manages lxc containers. It facilitaties the creation and
destruction of containers and system services to start and stop them.
This module also manages a virtual ethernet bridge and network
masquerading to allow the containers to connect to the world.

Currently this module support creating Arch Linux containers on an Arch
Linux host and Debian Squeeze and Wheezy containers on an Arch Linux,
Debian Squeeze or Debian Wheezy host. It was designed to be easily
extendible.

The network bridge facilitated by this module currently only supports
NAT. The default settings for the network bridge create a network
10.0.0.0/24 where the 'router' (the host) has address 10.0.0.1.

License
-------

Apache License, Version 2.0

Usage:
------

To create a new Arch Linux instance using all the default settings and an
IP address of 10.0.0.100, a sample would be:

<pre>
# class to setup a new Arch Linux container
class myarchcontainer {

  lxc::container::archlinux { 'myarchcontainer':
    ensure    => running,
    ipaddress => '10.0.0.100',
  }

}
</pre>

Contact
-------

Ingmar Steen <iksteen@gmail.com>
GitHub: http://github.com/iksteen/

Support
-------

Please log issues at the [project site](http://github.com/iksteen/puppet-lxc).
