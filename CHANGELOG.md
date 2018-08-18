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
