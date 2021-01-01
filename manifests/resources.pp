# == Class kerberos::resources
#
# Container class over Kerberos resources.
#
class kerberos::resources {
  Kerberos_policy <| |>
  -> Class['kerberos::resources']

  Kerberos_principal <| |>
  -> Class['kerberos::resources']

  Kerberos_keytab <| |>
  -> Class['kerberos::resources']
}
