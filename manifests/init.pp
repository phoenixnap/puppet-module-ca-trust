##
# Configures, and optionally installs, the ca-trust system.
##
class ca_trust (
  String $basedir = $ca_trust::params::basedir,
  String $update_cmd = $ca_trust::params::update_cmd,
  String $package_name = $ca_trust::params::package_name,
  Boolean $manage_pkg = $ca_trust::params::manage_pkg,
  String $package_version = $ca_trust::params::package_version,
) inherits ca_trust::params {

  $pth_fail = "%s is not an absolute path: %s"
  $sourcedir = "${basedir}/source"
  $anchordir = "${sourcedir}/anchors"

  if ! is_absolute_path($basedir){
    fail(sprintf($pth_fail, 'basedir', $basedir))
  }

  if ! is_absolute_path($sourcedir){
    fail(sprintf($pth_fail, 'sourcedir', $sourcedir))
  }

  if ! is_absolute_path($anchordir){
    fail(sprintf($pth_fail, 'anchordir', $anchordir))
  }

  if $manage_pkg {
    contain ca_trust::install
  }

  exec { "$update_cmd-refresh":
    command     => $update_cmd,
    refreshonly => true,
  }
}
