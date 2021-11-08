class { 'gitlab':
  external_url => 'http://10.8.1.239',
  gitlab_rails => {
    'db_adapter' => "postgresql",
    'db_encoding' => "unicode",
    'db_username' => "manager",
    'db_password' => "password",
    'db_host' => '10.8.1.239',
    'db_port' => 5432,
  },
  logging      => {
    'svlogd_size' => '200 * 1024 * 1024',
  },
}