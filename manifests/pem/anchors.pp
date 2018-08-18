##
# Allow for Hiera defined Ca_trust::Pem::Anchor(s).
##

class ca_trust::pem::anchors (
  Ca_trust::Resource::Anchors $resources = {},
){
  if $resources and $resources.length > 0 {
    create_resources(ca_trust::pem::anchor, $resources)
  }
}
