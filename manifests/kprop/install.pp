# == Class kerberos::kprop::install
#
# kpropd setup - installation.
#
class kerberos::kprop::install {
  include ::stdlib
  include ::kerberos::client

  ensure_packages($::kerberos::kpropd_packages)
}
