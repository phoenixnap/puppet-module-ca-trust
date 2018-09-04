# RELEASE 1.1.0 #

## Summary ##

The planned `list certs in bundle` task has been replaced with the `bundled_authorities` fact.  The idea to use a Puppet Task to do this was not a very good one.  Facts lend themselves to this sort of thing much better than tasks. Since this would have been a read-only operation anyway, I decided that task was not the way to go to do this.

The release of the task to list certs was planned to be the 1.1.0 release, so since that implementation has been scrubbed, I'll move forward with the 1.1.0 release being the introduction of the `bundled_authorities` fact.

Implemented a task which forces a rebuild of the trust bundle.

### Features ###

+ Implemented `bundled_authorities` fact.
+ Implemented `ca_trust::rebuild` task.

### Bugfixes ###

+ Fixed the reference docuementation that mistakenly labeled the `trust_bundle` fact as `trusted_bundle`.


# RELEASE 1.0.1 #

## Summary ##

Fixes a variety of bugs, and bumps PDK version.

### Features ###

+ ca\_trust::pem::anchor can now be specified with `content` instead of only `source`, so the raw content
of certificates can be used.  
  + [TODO: Allow CA cert to be set by content as well as source](https://github.com/phoenixnap/puppet-ca_trust/issues/4)
+ Updated module tools to [PDK](https://puppet.com/docs/pdk/1.x/pdk.html) 1.7.

### Bugfixes ###

+ [Documentation: reference examples](https://github.com/phoenixnap/puppet-ca_trust/issues/1)
  + ca\_trust::pem::anchor documentation didn\'t match implementation.
  + Relative links between documents don't work on the Forge website.
  + Some smples in REFERENCE.md show RHEL's default cert\_dir incorrectly.
+ [Bug: Type Ca\_trust::Resource::Anchor will fail when ensure: absent, and source: nil](https://github.com/phoenixnap/puppet-ca_trust/issues/3)
  + The ca\_trust::resource::anchor custom type doesn't match the expectation of ca\_trust::pem::anchor
+ [Documentation: Type Alias Examples](https://github.com/phoenixnap/puppet-ca_trust/issues/2)

# RELEASE 1.0.0 #

## Summary ##

This release provides the first implementation of core features.

### Features ###

+ Adds `Class ca_trust`. This class manages the RedHat/Debian ca-certificates capability.
+ Adds `Class ca_trust::pem::anchors`.  This class can be used for hiera convienience.  It 
  will pull in a hiera hash of `ca_trust::pem::anchor` values and create resources from it.
+ Adds `Type ca_trust::pem::anchor`.  This type adds/removes a CA anchor from the OS bundle.
+ Adds `Fact trust_bundle`.  This fact exposes the location of the system CA bundle.

### Bugfixes ###

+ *N/A*
