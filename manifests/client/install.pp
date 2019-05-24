# == Class kerberos::client::install
#
# Kerberos client setup - installation.
#
class kerberos::client::install {
  include ::stdlib

  if $::kerberos::client_packages {
    ensure_packages($::kerberos::client_packages)
  }
}
