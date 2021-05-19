<h1 align="center">
  <br>
  <a href="https://phoenixnap.com/bare-metal-cloud"><img src="https://user-images.githubusercontent.com/78744488/109779287-16da8600-7c06-11eb-81a1-97bf44983d33.png" alt="phoenixnap Bare Metal Cloud" width="300"></a>
  <br>
  ca_trust Puppet Module
  <br>
</h1>

<p align="center">
This repository contains instructions on how to manage additions to the root CA bundle supplied by the OS vendors using the ca_trust Puppet module. 
</p>

<p align="center">
  <a href="https://phoenixnap.com/bare-metal-cloud">Bare Metal Cloud</a> •
  <a href="https://forge.puppet.com/modules/phoenixnap">phoenixNAP Puppet modules</a> •
  <a href="https://developers.phoenixnap.com/">Developers Portal</a> •
  <a href="https://developers.phoenixnap.com/docs/bmc/1/overview">API Documentation</a> •
  <a href="http://phoenixnap.com/kb">Knowledge Base</a> •
  <a href="https://developers.phoenixnap.com/support">Support</a>
</p>

## Creating a Bare Metal Cloud Account
You need to have an account to use the ***ca_trust*** Puppet module with Bare Metal Cloud servers. 

1. Go to the [Bare Metal Cloud signup page](https://support.phoenixnap.com/wap-jpost3/bmcSignup).
2. Follow the prompts to set up your account.
3. Use your credentials to [log in to the Bare Metal Cloud portal](https://bmc.phoenixnap.com).

:arrow_forward: **Video tutorial:** [How to Create a Bare Metal Cloud Account](https://www.youtube.com/watch?v=RLRQOisEB-k)
<br>
:arrow_forward: **Video tutorial:** [Introduction to Bare Metal Cloud](https://www.youtube.com/watch?v=8TLsqgLDMN4)

## Table of Contents ##

+ [Overview](#overview)
    + [Supported Platforms](#support)
+ [Module Description](#descr)
+ [Setup](#setup)
+ [Usage](#usage)
    + [Legacy PEM Anchors](#pem-anchors)
    + [Anchors from Hiera](#hiera-config)
+ [Facts](#facts)
+ [Tasks](#tasks)
+ [Development](#dev)
+ [TODO](#todo)
+ [Changes](CHANGELOG)

---

## Overview <a name="overview" /> ##

Manage CA Trust anchors within the ca-certificates framework.

### Supported Platforms <a name="support"/> ###

+ RedHat and its derivatives >= 6.x
+ Debian and its derivatives >= 8.x
+ Fedora >= 25

:bulb: RedHat 6 and its derivatives, alongside Debian 8, are now deprecated. The EOL of these products is less than a year away. Support for these products will be removed when they reach end-of-life.

:bulb: CentOS 8 and Ubuntu 20 did not undergo acceptance testing yet. All other testing applies, but Beaker is not yet ready to support these platforms.

## Module Description <a name="descr" /> ##

The *ca_trust* module is for managing additions to the root CA bundle supplied by OS vendors. Used by applications to establish trust, the root CA bundle is usually shipped containing only third-party or commercial CA certificates. Administrators are expected to add their own internal or self-signed certificates to the OS vendor supplied bundles as needed.

The module currently supports adding PEM encoded CA anchors.

## Setup <a name="setup" /> ##

Prepare supported operating systems to receive new trusted CA anchors:

`include ca_trust`

To do the same, but include non-standard options:

```
class { '::ca_trust':
  cert_dir => '/some/other/directory',
}
```

See [Reference](REFERENCE#ca_trust) for all options supported by the main class.

## Usage <a name="usage"/> ##

The [Setup](#setup) process is unnecessary on supported operating systems. Simply begin by
declaring any [ca\_trust::pem::anchors](#pem-anchors) necessary.

If things need to be customized, the `ca_trust` main class can be specified explicitly, like it is in the 
[Setup](#setup) section. Alternatively, the `ca_trust` main class may be customized via Hiera.

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

To install new CA certificates into the operating system's trusted bundle, use the `ca_trust::pem::anchor` type. When specifying anchors, do not specify the filename extension such as *.crt*, *.pem*, etc. Some platforms are picky about the extension used, so the module will choose the appropriate default for the platform. For instance, Debian expects the certificates to end in *.crt*.

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

For convenience, you may also specify any anchors you'd like when you declare the `ca_trust` class, if you 
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

### Anchors from Hiera <a name="hiera-config"/> ###

The class `ca_trust::pem::anchors` is included for Hiera convenience. With it, you may pass in a hash 
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

The following facts are exposed:

+ `trust_bundle` - On supported operating systems, this fact resolves to the path of the system-wide trusted CA bundle.

+ `bundled_authorities` - This fact exposes pertinent information for each certificate in the bundle. It returns a hash, keyed on fingerprint.

Example:

```
$:facts['bundled_authorities'] = {
  b561ebeaa4dee4254b691a98a55747c234c7d971 => {
    subject => "/C=SK/L=Bratislava/O=Disig a.s./CN=CA Disig Root R2",
    issuer => "/C=SK/L=Bratislava/O=Disig a.s./CN=CA Disig Root R2",
    not_before => "2012-07-19 09:15:30 UTC",
    not_after => "2042-07-19 09:15:30 UTC"
  },
  ...,
  e2b8294b5584ab6b58c290466cac3fb8398f8483 => {
    subject => "/C=CN/O=China Financial Certification Authority/CN=CFCA EV ROOT",
    issuer => "/C=CN/O=China Financial Certification Authority/CN=CFCA EV ROOT",
    not_before => "2012-08-08 03:07:01 UTC",
    not_after => "2029-12-31 03:07:01 UTC"
  }
```

## Tasks <a name="tasks"/> ##

`ca_trust::rebuild` rebuilds the system's CA trust bundle using the operating system's prescribed manner.  

Note that this rebuild will include any `ca_trust::pem::anchors` already installed on the system. This will not reset the bundle to system default.

## Development <a name="dev"/> ##

This module has been converted to use the [Puppet Development Kit](https://puppet.com/docs/pdk/1.x/pdk.html).  

### Source Validation ###
`pdk validate`

### Unit Testing ###
`pdk test unit`

For better output, or to debug a specific spec, the old standby `bundle exec rake spec_prep` and `bundle exec rspec <filename>` still function flawlessly. Be sure to run `bundle exec rake spec_clean` before going back to `pdk test unit`, though.

## TODO <a name="todo"/> ##

+ When Beaker is ready to support CentOS 8 and Ubuntu 20, add them to nodesets.
+ Eventually support should be added for Windows platforms, to install new CAs into the system or user Certificate databases.

## Changes ##

See the [change log](CHANGELOG).

## Bare Metal Cloud Community
Become part of the Bare Metal Cloud community to get updates on new features, help us improve the platform, and engage with developers and other users. 

-   Follow [@phoenixNAP on Twitter](https://twitter.com/phoenixnap)
-   Join the [official Slack channel](https://phoenixnap.slack.com)
-   Sign up for our [Developers Monthly newsletter](https://phoenixnap.com/developers-monthly-newsletter)

### Bare Metal Cloud Resources
-	[Product page](https://phoenixnap.com/bare-metal-cloud)
-	[Instance pricing](https://phoenixnap.com/bare-metal-cloud/instances)
-	[YouTube tutorials](https://www.youtube.com/watch?v=8TLsqgLDMN4&list=PLWcrQnFWd54WwkHM0oPpR1BrAhxlsy1Rc&ab_channel=PhoenixNAPGlobalITServices)
-	[Developers Portal](https://developers.phoenixnap.com)
-	[Knowledge Base](https://phoenixnap.com/kb)
-	[Blog](https:/phoenixnap.com/blog)

### Documentation
-	[API documentation](https://developers.phoenixnap.com/docs/bmc/1/overview)

### Contact phoenixNAP
Get in touch with us if you have questions or need help with Bare Metal Cloud. 

<p align="left">
  <a href="https://twitter.com/phoenixNAP">Twitter</a> •
  <a href="https://www.facebook.com/phoenixnap">Facebook</a> •
  <a href="https://www.linkedin.com/company/phoenix-nap">LinkedIn</a> •
  <a href="https://www.instagram.com/phoenixnap">Instagram</a> •
  <a href="https://www.youtube.com/user/PhoenixNAPdatacenter">YouTube</a> •
  <a href="https://developers.phoenixnap.com/support">Email</a> 
</p>

<p align="center">
  <br>
  <a href="https://phoenixnap.com/bare-metal-cloud"><img src="https://user-images.githubusercontent.com/81640346/115243282-0c773b80-a123-11eb-9de7-59e3934a5712.jpg" alt="phoenixnap Bare Metal Cloud"></a>
</p>

