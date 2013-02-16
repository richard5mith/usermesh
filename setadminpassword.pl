#!/usr/bin/env perl

use strict;

use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use YAML::XS qw(LoadFile DumpFile);
use Digest::MD5 qw(md5_hex);

use Usermesh();
my $um = Usermesh->new();

if (!$ARGV[0]) {
	die "Specify your admin password. setadminpassword.pl [password]";	
}

my $config = LoadFile($um->documentroot . "/config/main.yaml");

$config->{adminpassword} = md5_hex(md5_hex($ARGV[0]));

DumpFile($um->documentroot . "/config/main.yaml", $config);

