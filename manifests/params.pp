##
# Default parameters for ca_trust system.
##
class ca_trust::params {

  $package_name = 'ca-certificates'
  $path_separator = '/'   # Might need to adjust if Windows support is added.

  case $::facts['os']['family'] {
    'RedHat':  {

      if $::facts['os']['name'] == 'Fedora' {
        if versioncmp('27', $::facts['os']['release']['major']) > 0 {
          fail('Fedora <= 25 is not supported by this module.')
        }
      } else {
        if versioncmp('6', $::facts['os']['release']['major']) > 0 {
          fail("${::facts['os']['name']} <= 6 is not supported by this module.")
        }
        # Add deprication warning for CentOS 6.x EOL
        if $::facts['os']['release']['major'] == '6' {
          warning(
            [
              'Deprication:  CentOS 6 will reach end of life in November, 2020.',
              'This module will no longer test for CentOS 6 support.'
            ].join('  ')
          )
        }
      }

      $trust_dir = '/usr/share/pki/ca-trust-source'
      $anchor_dir = "${trust_dir}/anchors"
      $update_cmd = $::facts['os']['release']['major'] ? {
        '6'     => 'update-ca-trust extract',
        default => 'update-ca-trust'
      }

      $reset_cmd = "yum check-update ${package_name}; test $? -eq 100 && yum update -y ${package_name} || yum reinstall -y ${package_name}"
      $cert_suffix = 'pem'
    }
    'Debian': {
      if $::facts['os']['name'] == 'Ubuntu' {
        if versioncmp('16', $::facts['os']['release']['major']) > 0 {
          fail("${::facts['os']['name']} <= 16 is not supported by this module.")
        }
      } else {
        if versioncmp('8', $::facts['os']['release']['major']) > 0 {
          fail("${::facts['os']['name']} <= 8 is not supported by this module.")
        }

        # Add deprication warning for Debian 8 EOL
        if $::facts['os']['release']['major'] == '8' {
          warning(
            [
              'Deprication: Debian 8 will reach end of long term support in July, 2020.',
              'This module will no longer test for Debian 8 support.'
            ].join('  ')
          )
        }
      }
      $trust_dir = '/usr/local/share/ca-certificates'
      $anchor_dir = $trust_dir
      $update_cmd = '/usr/sbin/update-ca-certificates'
      $reset_cmd = '/usr/sbin/update-ca-certificates --fresh'
      $cert_suffix = 'crt'
    }
    default: {
      fail("This module is unsupported on ${::os['family']}")
    }
  }
}
