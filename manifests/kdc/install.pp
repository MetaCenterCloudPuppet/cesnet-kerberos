# == Class kerberos::kdc::install
#
# KDC Server setup - installation.
#
class kerberos::kdc::install {
  include ::stdlib

  ensure_packages($::kerberos::kdc_packages)
}
