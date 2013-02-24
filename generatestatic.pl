#!/usr/bin/env perl

# Generates the static version of your site
# Run this whenever you want to make sure everything is up to date

use strict;

use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use Usermesh();
use Usermesh::Helpers::Generator();

my $um = Usermesh->new();
my $generator = Usermesh::Helpers::Generator->new($um);

my $totalwritten = $generator->run($ARGV[0]);

print "Generated $totalwritten pages.\n";


