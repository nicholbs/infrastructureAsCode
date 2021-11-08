class { 'postgresql::globals':
  manage_package_repo => true,
  version             => '12',
}

class { 'postgresql::server':
  listen_addresses           => '*',
  postgres_password          => 'password',
}

postgresql::server::db { 'gitlabhq_production':
  user     => 'manager',
  password => postgresql::postgresql_password('manager', 'password'),
}

postgresql::server::role { 'manager':
  password_hash => postgresql::postgresql_password('manager', 'password'),
  superuser => true;
}

postgresql::server::database_grant { 'gitlabhq_production':
  privilege => 'ALL',
  db        => 'gitlabhq_production',
  role      => 'manager',
}

postgresql::server::pg_hba_rule { 'allow application network to access app database':
  description => 'Open up PostgreSQL for access from anyone',
  type        => 'host',
  database    => 'all',
  user        => 'all',
  address     => '0.0.0.0/0',
  auth_method => 'md5',
}