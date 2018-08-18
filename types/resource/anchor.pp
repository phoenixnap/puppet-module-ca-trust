##
# A type used to validate ca_trust::pem::anchor passed in as a hash.
##

type Ca_trust::Resource::Anchor = Struct[{
  Optional[ensure]   => Enum['present','absent'],
  source             => String[1],
  Optional[filename] => Pattern[/\A[^\\\/]+\z/],
}]
