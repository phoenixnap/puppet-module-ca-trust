##
# Installs ca-trust pacakges.
# This is usually not required as ca-trust is most often
# part of base system.
##
class ca_trust::install {

  if $ca_trust::manage_pkg {
    package { $ca_trust::package_name :
      ensure => $ca_trust::package_version,
    }
  }

}
