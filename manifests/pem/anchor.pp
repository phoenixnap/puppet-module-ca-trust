##
# Installs a legacy PEM format anchor, and updates the trusted bundle.
#
# @PARAM $source   - The source of the PEM file. I ensure is not 'present', this is required, 
#                    otherwise it's optional as it's ignored. (Default: undef).
# @PARAM $ensure   - Generic puppet ensurable. (Default: present)
# @PARAM $filename - The name of the file the source will be installed as. This is the filename
#                    only, not any sort of relative or absolute path. The filename must end in
#                    .pem or .crt.  (Default: $namevar)
## 
define ca_trust::pem::anchor (
  Optional[String]         $source   = undef,
  Enum['present','absent'] $ensure   = 'present',
  Pattern[/\A[^\\\/]+\z/]  $filename = $title,
) {

  include ca_trust

  if $ensure != 'present' {
    $notify = [Exec[$::ca_trust::reset_name]]
  } else {
    unless $source { fail('Source is required if ensure is \'present\'') }
    $notify = [Exec[$::ca_trust::refresh_name]]
  }


  $install_path = [$::ca_trust::anchor_dir, $filename].join($::ca_trust::path_separator)

  file { "${install_path}.${::ca_trust::cert_suffix}":
    ensure => $ensure,
    source => $source,
    notify => $notify,
  }
}
