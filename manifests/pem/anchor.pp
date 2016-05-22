##
# Installs a legacy PEM format anchor, and updates the trusted bundle.
## 
define ca_trust::pem::anchor (
  Optional[String] $filename = undef,
  String $source = undef,
  Enum['present','absent'] $ensure = 'present',
) {

  if ! defined(Class['ca_trust']) {
    fail("Class['ca_trust'] must be loaded before ca_trust::anchor can be declared.")
  }

  if ! $filename {
    $_target_file = $title
    $_target = "${ca_trust::anchordir}/${title}"
  } else {
    $_target_file = $filename
    $_target = "${ca_trust::anchordir}/${filename}"
  }

  if $ensure == 'present' {
    $_ensure = 'file'
  } else {
    $_ensure = $ensure
  }

  if defined(File[$_target]){
    notify { "Target $_target exists.":
      message => "Trust anchor File['${_target}'] is declared elsewhere. ca_trust will not manage."
    }
  } else {
    # Parent directories should be made by package.
    file { $_target :
      ensure  => $_ensure,
      owner   => root,
      group   => root,
      mode    => '0640',
      source  => $source,
      notify  => Class['ca_trust'],
    }
  }
}
