# == Class kerberos::kadmin::install
#
# kadmin setup - installation.
#
class kerberos::kadmin::install {
  include ::stdlib
  include ::kerberos::client

  ensure_packages($::kerberos::kadmin_packages)
}
