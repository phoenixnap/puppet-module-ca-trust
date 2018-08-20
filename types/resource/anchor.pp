##
# A type used to validate ca_trust::pem::anchor passed in as a hash.
##

type Ca_trust::Resource::Anchor = Struct[{
  Optional[ensure]   => Enum['present','absent'],
  Optional[content]  => String[1],
  Optional[source]   => String[1],
  Optional[filename] => Pattern[/\A[^\\\/]+[^(\.pem|\.crt)]\z/],
}]
