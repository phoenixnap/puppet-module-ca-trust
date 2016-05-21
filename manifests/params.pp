##
# Default parameters for ca_trust system.
##
class ca_trust::params {
  
  case $::os['family'] {
    'RedHat':  {
      $basedir = '/etc/pki/ca-trust'
      $update_cmd = '/usr/bin/update-ca-trust'
      $package_name = 'ca-certificates'
      $manage_pkg = false
      $package_version = 'installed'
    }
    default: {
      fail("This module is unsupported on ${::os['family']}")
    }
  }
}
