##
# Configures, and optionally installs, the ca-trust system.
# @PARAM $trust_dir       - The top level directory under which anchors, and other PKI files are stored.
#                           (Default: OS Dependent).
# @PARAM $anchor_dir      - The directory which is designed to contain loose certificate files. This module
#                           does not create this, or parent directories.  It assumes the directories were provided
#                           by the operating system package.  (Default: OS Dependent)
# @PARAM $update_cmd      - The command to run in order to update the CA bundle. (Default: OS Dependent)
# @PARAM $reset_cmd       - The command to run in ordre to reset the CA Bundle.
# @PARAM $package_name    - The name of the package which provides the update command. (Default: OS Dependent)
# @PaRAM $cert_suffix     - On some platforms, new certificates will not be detected unless they have a specific
#                           file extension.  This parameter sets that file extension. (Default: OS Dependent).
# @PARAM $manage_pkg      - If true, the package will be installed if it is not present. Otherwise no action
#                           will be taken.
# @PARAM $package_version - The version of the CA trust package to use. (Default: present).
# @PARAM $anchors         - A hash of Ca_trust::Resource::Anchor resources that will be auto-created. (Default: {})
##
class ca_trust (
  Stdlib::Absolutepath        $trust_dir       = $::ca_trust::params::trust_dir,
  Stdlib::Absolutepath        $anchor_dir      = $::ca_trust::params::anchor_dir,
  String                      $update_cmd      = $::ca_trust::params::update_cmd,
  String                      $reset_cmd       = $::ca_trust::params::reset_cmd,
  String[1]                   $package_name    = $::ca_trust::params::package_name,
  String[1]                   $cert_suffix     = $::ca_trust::params::cert_suffix,
  Boolean                     $manage_pkg      = true,
  String                      $package_version = 'present',
  Ca_trust::Resource::Anchors $anchors         = {}
) inherits ca_trust::params {

  $refresh_name = 'Update CA Trust Bundles'
  $reset_name = 'Reset CA Trust Bundles'

  contain ca_trust::install
  include ca_trust::pem::anchors

  ##
  # The update commands can be shell scripts. On Debian, the
  # shell script doesn't export it's own PATH, so it relies on
  # whatever PATH the invoker has declared.  Since this script
  # doesn't use absolute paths internally, it needs a full
  # login-style PATH declared.
  # In other words, even if command is an absolute path, the PATH
  # variable still needs to be declared, or the command will fail.
  ## 

  $cmd_path = [
    '/bin', '/usr/bin', '/sbin', '/usr/bin', '/usr/local/bin'
  ]

  exec { $refresh_name:
    path        => $cmd_path,
    command     => $update_cmd,
    refreshonly => true,
  }

  exec { $reset_name:
    path        => $cmd_path,
    command     => $reset_cmd,
    provider    => 'shell',
    refreshonly => true,
    notify      => [Exec[$refresh_name]],
  }

  Class['::ca_trust::install']
  -> Class['::ca_trust::pem::anchors']

  if $anchors.length > 0 {
    create_resources(ca_trust::pem::anchor, $anchors)
  }
}
