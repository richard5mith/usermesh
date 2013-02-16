#!/usr/bin/env perl

use strict;

use Data::Dumper;
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use Data::Dumper;

use Usermesh();
use Usermesh::Helpers::Date();
use Usermesh::Plugins::Blog();

my $um = Usermesh->new();
my $date = Usermesh::Helpers::Date->new($um);
my $blog = Usermesh::Plugins::Blog->new($um);

my $title = join(" ", @ARGV);

my $timestamp = $date->unixtotimestamp(time);
my ($year, $month, $day) = split(/-/, substr($timestamp, 0, 10), 3);

my $nicetitle = $um->makeniceurl($title);

$blog->savepost("$year-$month-$day-$nicetitle", { title => $title, date => $timestamp, categories => [ "Other" ], body => "", niceurl => "/$year/$month/$day/$nicetitle/" }); 

exec("pico data/blog/$year-$month-$day-$nicetitle.md");


