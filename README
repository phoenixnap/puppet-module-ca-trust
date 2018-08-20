# ca\_trust #

### Table of Contents ###

+ [Overview](#overview)
    + [Supported Platforms](#support)
+ [Module Description](#descr)
+ [Setup](#setup)
+ [Usage](#usage)
    + [Legacy PEM Anchors](#pem-anchors)
    + [Anchors from Hiera](#hiera-config)
+ [Facts](#facts)
+ [Development](#dev)
+ [TODO](#todo)
+ [Changes](CHANGELOG)

---

## Overview <a name="overview" /> ##

Manage CA Trust anchors within the ca-certificates framework.

### Supported Platforms <a name="supported"/> ###

+ RedHat & Derivatives >= 6.x
+ Debian & Derivatives >= 8.x
+ Fedora >= 25

## Module Description <a name="descr" /> ##

The ca\_trust module is for managing additions to the root CA bundle supplied by OS vendors. Used by applications
to establish trust, the root CA bundle is usually shipped containing only 3rd party or commercial CA certificates.
Administrators are expected to add their own internal or self signed certificates to the OS vendor supplied bundles
as needed.

The module currently supports adding PEM encoded CA anchors.

## Setup <a name="setup" /> ##

To prepare supported operating systems to receive new trusted CA anchors.

`include ca_trust`

To do the same, but include non-standard options.

```
class { '::ca_trust':
  cert_dir => '/some/other/directory',
}
```

See [Reference](REFERENCE#ca_trust) for all options supported by the main class.

## Usage <a name="usage"/> ##

On supported operating systems, the [Setup](#setup) process is entirely unnecessary, simply begin by
declaring any [ca\_trust::pem::anchors](#pem-anchors) necessary.

If things need to be customized, then the `ca_trust` main class can be specified explicitly, like it is in the 
[Setup](#setup) section.  Alternatively, the `ca_trust` main class may be customized via hiera.

```
---
# Hiera YAML file.
# Use some other command to update root bundle certificates instead of
# OS default.
ca_trust::update_cmd: /some/other/binary
```

```
# Puppet profile.

include ca_trust
```

### Legacy PEM Anchors <a name="pem-anchors"/> ###

To install new CA certificates into the operating system's trusted bundle, use the `ca_trust::pem::anchor` type.  When 
specifying anchors, do not specify the filename extension (.crt, .pem, etc.).  Some platforms are picky about the extension
used, so the module will choose the appropriate default for the platform.  For instance, Debian expects the certificates to end
in .crt.

```
ca_trust::pem::anchor { 'self-signed':
  source => 'puppet:///modules/profile/node-one/self-signed-cert.pem',
}

ca_trust::pem::anchor { 'expired-cert':
  ensure => 'absent',
}

ca_trust::pem::anchor { 'My Company\'s Internal CA':
  source   => 'puppet:///modules/profile/organization-ca.pem',
  filename => 'org-ca',
}

$cert_data = @(EOT)
----- BEGIN CERTIFICATE -----
...blah blah blah, PEM encoded certificate here....
----- END CERTIFICATE -----
| EOT

ca_trust::pem::anchor { 'Org-CA':
  content => $cert_data,
}
```

For convienience you may also specify any anchors you'd like when you declare the `ca_trust` class, if you 
are doing so explicitly.

```
class { '::ca_trust':
  update_cmd => 'my-custom-command.sh',
  anchors    => {
    'org-ca' => {
      'source' => 'puppet:///modules/profile/my-company-ca.pem',
    },
    'expired-ca' => {
      'ensure' => 'absent',
    },
  },
}
```

### Anchors from Hiera ###

The class `ca_trust::pem::anchors` is included for hiera convienience.   With it, you may pass in a hash 
of `ca_trust::pem::anchor` resources to manage.

```
---
# Node's hiera yaml.
ca_trust::pem::anchors::resources:
  org-ca: 
    source: puppet:///modules/profile/my-company-ca.pem
  expired-ca:
    ensure: absent
  my-ca:
    content: >
      ----- BEGIN CERTIFICATE ------
      .... cert data here .....
      ----- END CERTIFICATE -----
```

## Facts <a name="facts"/> ##

The following facts are exposed.

`trust_bundle` - On supported operating systems this fact resolves to the path of the system-wide trusted CA bundle.

## Development <a name="dev"/> ##

This module has been converted to use the [Puppet Development Kit](https://puppet.com/docs/pdk/1.x/pdk.html).  

### Source Validation ###
`pdk validate`

### Unit Testing ###
`pdk test unit`

For better output, or to debug a specific spec, the old standby `bundle exec rake spec_prep` and `bundle exec rspec <filename>` still
functions flawlessly.  Be sure to run `bundle exec rake spec_clean` before going back to `pdk test unit` though.

## TODO <a name="todo"/> ##

+ Right now, only PEM encoded certificate anchors are supported. Support for other types of anchors, as well as BEGIN TRUSTED certs should be added.
+ Add a task which allow administrators to view the contents of their system CA bundles.
+ Eventually support should be added for Windows platforms, to install new CA's into the system or user Certificate databases.

## Changes ##

See the [change log](CHANGELOG).
