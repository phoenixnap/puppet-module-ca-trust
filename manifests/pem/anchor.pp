##
# Installs a legacy PEM format anchor, and updates the trusted bundle.
#
# @PARAM $source   - The source of the PEM file. If ensure is present, one of source or content
#                    is required. Otherwise it's optional as it's ignored. (Default: undef).
# @PARAM $content  - Set the content of the PEM file.  If ensure is present, one of source or 
#                    content is required.  (Default: undef)
# @PARAM $ensure   - Generic puppet ensurable. (Default: present)
# @PARAM $filename - The name of the file the source will be installed as. This is the filename
#                    only, not any sort of relative or absolute path. The filename must end in
#                    .pem or .crt.  (Default: $namevar)
## 
define ca_trust::pem::anchor (
  Optional[String[1]]                      $source   = undef,
  Optional[String[1]]                      $content  = undef,
  Enum['present','absent']                 $ensure   = 'present',
  Pattern[/\A[^\\\/]+[^(\.pem|\.crt)]\z/]  $filename = $title,
) {

  include ca_trust

  if $ensure != 'present' {
    $notify = [Exec[$::ca_trust::reset_name]]
  } else {
    unless ( $source or $content ){ fail('Source or content is required if ensure is \'present\'') }
    $notify = [Exec[$::ca_trust::refresh_name]]
  }


  $install_path = [$::ca_trust::anchor_dir, $filename].join($::ca_trust::path_separator)

  if $content {
    file { "${install_path}.${::ca_trust::cert_suffix}":
      ensure  => $ensure,
      content => $content,
      notify  => $notify,
    }
  } else {
    file { "${install_path}.${::ca_trust::cert_suffix}":
      ensure => $ensure,
      source => $source,
      notify => $notify,
    }
  }
}
