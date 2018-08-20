# Reference #

## Class Index ##

### Public Classes ###

* [ca\_trust](#ca_trust):  Main class for module.
* [ca\_trust::pem::anchors](#pem_anchors): Expands hash of `ca_trust::pem::anchor` types into declared resources.

### Private Clases ###
* `ca_trust::params`: OS Specific defaults.
* `ca_trust::install`: Manages package installation

## Defined Type Index ##

### Public Defined Types ###
* [ca\_trust::pem::anchor](#pem_anchor): Create or remove a CA certificate in/from the trusted bundle.

## Type Alias Index ##

### Public Aliases ###
* [ca\_trust::resources::anchor](#alias_anchor): Defines the standard for anchor resources.
* [ca\_trust::resources::anchors](#alias_anchors): Defines the standard for a hash of anchor resources.

## Fact Index ##
* [trusted_bundle](#fact_trusted_bundle): Resolves to the absolute path of the system CA bundle.


## Public Classes ##

### ca\_trust <a name="ca_trust"/> ###

#### Example ####

Customize the ca\_trust system.

```
class { '::ca_trust':
  cert_dir        => '/usr/share/pki/ca-trust-source',
  update_cmd      => 'custom_updater.sh',
  package_name    => 'customized-ca-certs',
  package_version => '1.0.0',
  anchors         => { 
    'my-ca' => {
      source => 'puppet:///profile/self-signed.crt',
    },
  },
}
```

#### Parameters ####
`cert_dir`

Data Type: `Stdlib::Absolutepath`

Description: The directory which is designed to contain loose certificate files. This module does not create this, or parent directories.  It assumes the directories were provided by the operating system package.

Default Value:  OS Dependent
* RedHat & Derivatives: /usr/share/pki/ca-trust-source
* Debian & Derivatives: /usr/local/share/ca-certificates

`update_cmd`

Data Type: String

Description: Name of the command to invoke in order to rebuild the root CA bundle out of loose certificate files.

Default Value: OS Dependent
* RedHat & Derivatives: update-ca-trust
* Debian & Derivatives: update-ca-certificates

`package_name`

Data Type: String

Description: The name of the package which provides the `cert_dir` and `update_cmd`.

Default Value: OS Dependent, just happens to be the same on all supported OSes at the moment.
* RedHat, Debian & Derivatives: ca-certificates

`package_version`

Data Type: String

Description: Specify the precise version of the `package_name` package to install or pin.  Besides a version, this parameter also accepts `present`, `installed` and `latest`.  See [Puppet Package Resource](https://puppet.com/docs/puppet/5.5/types/package.html) for more details about thise options.

Default Value: present

`manage_pkg`

Data Type: Boolean

Description: If set to true, this module will ensure that the CA Trust package is installed, and is of the version specified by `package_version`.  If set to false, this module will ignore the package entirely.

Default Value: true

`anchors`

Data Type: Ca\_Trust::Resource::Anchors

Description: An optional hash of `ca_trust::pem::anchor` resources that will be autocreated.

Default Value: `{}`


### ca\_trust::pem::anchors <a name='pem_anchors'/> ###

#### Example 1 ####

Create multiple `ca_trust::pem::anchor` resources with a hash.

```
$cert_data = @(EOT)
----- BEGIN CERTIFICATE -----
... certificate data ...
----- END CERTIFICATE -----
| EOT

$anchors = {
  'org-ca' => {
    'source' => 'puppet:///modules/profile/company-ca.pem',
  },
  'self-signed' => {
    'source' => 'puppet:///modules/profile/node_one/cert.crt',
  },
  'expired-ca' => {
    'ensure' => 'absent',
  },
  'another-ca' => {
    'content' => $cert_data,
  }
}

class { '::ca_trust::pem::anchors':
  anchors => $anchors,
}
```

#### Example 2 ####

The main purpose of this class is for hiera convienience.

```
---
# In the hiera YAML.
ca_trust::pem::anchors::resources:
  org-ca:
    source: puppet:///modules/profile/company-ca.pem
  self-signed:
    source: puppet:///modules/profile/node_one/cert.crt
  expired-ca:
    ensure: absent
  another-ca:
    content: >
      ----- BEGIN CERTIFICATE -----
      .... data here .....
      ----- END CERTIFICATE -----
```

```
# Node profile.
include ca_trust::pem::anchors
```

#### Parameters ####
`resources`
Data Type: `ca_trust::resource::anchors`

A hash of `ca_trust::pem::anchor` resources.

Default Value: `{}`


## Public Defined Types ##

### ca\_trust::pem::anchor <a name='pem_anchor' />###

#### Example ####

```
ca_trust::pem::anchor { 'ca-cert':
  ensure   => 'present',
  source   => 'puppet:///modules/profile/ca-cert.pem',
  filename => 'ca-cert'
}

$cert_data = @(EOT)
----- BEGIN CERTIFICATE -----
... cert data ...
----- END CERTIFICATE -----
| EOT

ca_trust::pem::anchor { 'ca-cert-from-content':
  ensure  => 'present',
  content => $cert_data,
}

@
```

#### Parameters ####
`ensure`

Data Type: `Enum['present','absent']`

Description: If `present` the CA anchor will be created on the filesystem.  If absent, the CA anchor will be removed from the filesystem
if it existed.  In either case, the CA bundle update command will be notified.

Default Value: `present`

`source`

Data Type: `String`

Description: The location from which the specified anchor will be downloaded.  See [Puppet File Resource: source](https://puppet.com/docs/puppet/5.5/types/file.html#file-attribute-source) parameter documentation for more details.   One of content or source must be specified if `ensure` is `present`.  If both source and content are defined, content takes precedence.

Default Value: None, undef.

`content`
Data Type: `String`

Description: The contents of the certificate to be written to the file.  One of source or content must be specified if `ensure` is `present`.  If both are specified, content takes precedence.  See [Puppet File Resource: content](https://puppet.com/docs/puppet/5.5/types/file.html#file-attribute-content) for more details.  

Default Value: None, undef

Description

`filename`
Data Type: `Pattern[/\A[^\\\/]+\z/]`

Description: The name of the file that will be created inside the `cert_dir` when the CA anchor is created. This is not an absolute path, just a file name without an extension.

Default Value: (namevar)

## Public Aliases ##

### ca\_trust::resources::anchor <a name='alias_anchor'/> ###

#### Definition ####

```
type Ca_trust::Resource::Anchor = Struct[{
  Optional[ensure]   => Enum['present','absent'],
  source             => String[1],
  Optional[filename] => Pattern[/\A[^\\\/]+[^(\.pem|\.crt)]\z],
}]
```

#### Example Matching Values ####

```
{ 
  'source' => 'puppet:///modules/profile/my-internal-ca.pem',
}

{ 
  'ensure' => 'present',
  'source' => 'puppet:///modules/profile/my-internal-ca.pem',
}

{ 
  'ensure'   => 'absent',
  'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
  'filename' => 'org-ca',
}
```

### ca\_trust::resources::anchors <a name='alias_anchors'/> ###

#### Definition ####

```
type Ca_trust::Resource::Anchors = Hash[String[1], Ca_trust::Resource::Anchor]
```

#### Example Matching Values ####

```
{ 
  'org-ca' => {
    'source' => 'puppet:///modules/profile/my-internal-ca.pem',
  },
  'another' => {
    'ensure' => 'present',
    'source' => 'puppet:///modules/profile/my-internal-ca.pem',
  },
  'my-company-ca' => {
    'ensure'   => 'absent',
    'source'   => 'puppet:///modules/profile/my-internal-ca.pem',
    'filename' => 'org-ca',
  },
},
```

## Fact Index ##

`Facts['trust_bundle']` - Resolves to the path of the systemwide CA trust PEM bundle.  
                          On RedHat & deriviatives this file should be under /etc/pki/, 
                          on Debian bases, it will be under /etc/ssl.
