# ca\_trust #

### Table of Contents ###

+ [Overview](#overview)
+ [Module Description](#descr)
+ [Setup](#setup)
+ [Usage](#usage)
    + [Legacy PEM Anchors](#pem-anchors)
+ [Reference](#reference)
+ [Development](#dev)
+ [TODO](#todo)

---

## Overview <a name="overview" /> ##

Manage configuration of the recent /etc/pki/ca-trust system.

## Module Description <a name="descr" /> ##

The ca\_trust module is for applying configuration to the /etc/pki/ca-trust system.  
Trusted certificates can be imported into the trusted bundles.

## Setup <a name="setup" /> ##

Installing the module provides everything necessary to start using the system, though
Hiera and Puppet file server configurations make things simpler.

## Usage <a name="usage"/> ##

Set up the basic requirements of ca\_trust.

```
import ::ca_trust 
```

In most cases, the ca\_trust packages are provided with the 'base' or 'minimal' install
of the operating system.  If your OS vendor does not include this system by default, 
the module can manage that for you.

```
class { '::ca_trust' :
  manage_pkg       => true,
  package_name     => 'ca-certificates',
  package_version  => 'latest',
}
```

If your operating system's default paths aren't listed in `ca_trust::params`, or if you have
the ca-trust system configured to use a default directory.

```
class { '::ca_trust':
  basedir => '/my/custom/location'
}
```

### Legacy PEM Anchors <a name="pem-anchors"/> ###

Once the ca\_trust class is loaded & configured, PEM anchors may be appended to the system's
CA bundle.

```
include ::ca_trust

ca_trust::pem::anchor { 'my-local-ca.pem':
  ensure => 'present',
  content => 'puppet:///modules/profile/local-ca.pem',
}
```

### Reference <a name="reference"/> ###

```
class { 'ca_trust':
  basedir         =>  # The location of the ca-trust tree. Default '/etc/pki/ca-trust'
  update_cmd      =>  # The shell command to update trusted bundles.
                      # Default: '/usr/bin/update-ca-trust'
  package_name    =>  # The name of the package which provides ca-trust.
                      #  Default: ca-certificates
  manage_pkg      =>  # A boolean flag indicating whether or not the installation of
                      # the ca-certificates package should be managed.
  package_version =>  # The version of the package to install, 'latest' or 'installed.
                      # Default: 'installed'
``` 

```
ca_trust::pem::anchor { 'resource title':
  filename =>  # (namevar) The name of the target file. Not a path, just a file.
  content  =>  # Same as built-in File content.
  ensure   =>  # One of 'present', 'absent'.  If 'present', file will be installed
               # and merged with OS ca-bundle.  If 'absent', file will be removed
               # from OS ca-bundle.
}
```

## Development <a name="dev"/> ##

Coming soon.

## TODO <a name="todo"/> ##

+ Right now, only legacy PEM anchors are supported. Support for other
types of anchors, as well as BEGIN TRUSTED certs must be added.
