# time.pp:

node default {
  include ntp
  class { 'timezone':
    timezone => 'Europe/Oslo',
  }
}