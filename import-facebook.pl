#!/usr/bin/env perl

# Import Facebook
# This allows you to convert your Facebook stream to a list of blog posts
# You need to create an app on Facebook and authorise it to access your account first, instructions for which you'll find in the Usermesh control panel
# It's safe to run multiple times, it's sensible enough to get as much of your Facebook stream as it can first time around
# and then each time afterwards it'll just get what's new. Stick it in your cron.

use strict;

use Data::Dumper;
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use Storable qw(store retrieve);
use Data::Dumper;
use Facebook::Graph();

use Usermesh();
use Usermesh::Helpers::Date();
use Usermesh::Plugins::Blog();

my $um = Usermesh->new();
my $date = Usermesh::Helpers::Date->new($um);
my $blog = Usermesh::Plugins::Blog->new($um);

my $config = $um->loadconfig();

# Always auth first, because we can't do anything without it
my $fb = auth();

# And then export
export($fb);

# And then convert to posts
createposts();

sub auth {

	my $keyfile = $um->documentroot() . "/data/facebookkey.dat";	
	my $keydata = eval { retrieve($keyfile) } || {};
	
	if ($keydata->{app_id} eq "" or $keydata->{secret} eq "") {
		die "No application details found. You must authorise your connection to Facebook through the control panel first.";
	}
	
	my $fb = Facebook::Graph->new(%{$keydata});
	
	my $datafile = $um->documentroot() . "/data/facebookauth.dat";	
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$fb->access_token($access_tokens->[0]);
	} else {
		die "No authorisation found. You must authorise your connection to Facebook through the control panel first.";		
	}

	return $fb;

}

sub export {
	
	my $fb = shift;	
	
	my @statuses = ();
	my $untiltime = undef;
	my $sincetime = undef;
	my $export = 1;
	my $count = 25;
	my $datafile = $um->documentroot . "/data/facebookstream.dat";
	my $fullexport = 0;
	
	# Open in our statuses file
	my $storedstatus = eval { retrieve($datafile) } || [];
	if ($#{$storedstatus} != -1) {
		@statuses = @{$storedstatus};
		$sincetime = $storedstatus->[0]->{created_time};
	} else {
		$fullexport = 1;
	}
	
	print "First run, so doing a full export.\n" if ($fullexport);
	
	while ($export) {
		
		my ($statuslist, $response);
		if (!$fullexport and $sincetime) {
			print "Requesting posts since $sincetime\n";
			$response = $fb->query->find('me/posts')->where_since($sincetime)->limit_results($count)->date_format('U')->request->as_hashref;

		} elsif ($untiltime) {
			print "Requesting posts before $untiltime\n";
			$response = $fb->query->find('me/posts')->where_until($untiltime)->limit_results($count)->date_format('U')->request->as_hashref;

		} else {
			print "Requesting the last $count posts\n";
			$response = $fb->query->find('me/posts')->limit_results($count)->date_format('U')->request->as_hashref;

		}
		
		if (ref($response->{data}) eq "ARRAY") {
			$statuslist = $response->{data};
			
			if ($#{$statuslist} != -1) {
				print "Got " . ($#{$statuslist} + 1) . " posts\n";
				
				# Set the untiltime to the last one we got
				$untiltime = $statuslist->[$#{$statuslist}]->{created_time} - 1;
				
				# And sinceid to the first
				$sincetime = $statuslist->[0]->{created_time}; 
				
				# Store these ones
				if ($fullexport) {
					push @statuses, @{$statuslist};				
				} else {
					unshift @statuses, @{$statuslist};
				}
						
			} else {
				print "No more posts\n";
				$export = 0;
			}			
		} else {
			print "Bad response.\n";
			$export = 0;
		}
		
	}
	
	store(\@statuses, $datafile);
	
}

sub createposts {

	my $datafile = $um->documentroot . "/data/facebookstream.dat";
	my $storedstatus = eval { retrieve($datafile) } || [];

	if ($#{$storedstatus} == -1) {
		return undef;
	}
	
	my $generated = 0;
	
	foreach my $post (@{$storedstatus}) {

		# TODO: This could certainly do with some type parsing, photos for example would be good to download and place inline
		# TODO: It could also make the privacy setting configurable in the control panel
		next if (not $post->{type} ~~ [ qw(status video) ]);
		#next if ($post->{privacy}->{description} ne "Public");
		next if ($post->{status_type} ne "app_created_story" and $post->{status_type} !~ /status_update/ and $post->{status_type} ne "shared_story");			

		my $createdate = $post->{created_time};
		my $timestamp = $date->unixtotimestamp($createdate);

		my $saved = 0;
		if ($post->{type} eq "video") {
			if ($post->{link} =~ /youtube/) {
				$saved = savepost({ timestamp => $timestamp, id => $post->{id}, body => $post->{message}, category => "Video" });
			}

		} elsif ($post->{type} eq "status") {
			$saved = savepost({ timestamp => $timestamp, id => $post->{id}, body => $post->{message}, category => "Other" });
		
		}
		
		if ($saved) {
			$generated++;
		}
	}
	
	print "Generated $generated new posts.\n";		

}

sub savepost {
	
	my $p = shift;
	
	my ($year, $month, $day) = split(/-/, substr($p->{timestamp}, 0, 10), 3);

	return $blog->savepost("$year-$month-$day-$p->{id}", { type => "facebook", date => $p->{timestamp}, categories => [ $p->{category} ], body => $p->{body}, niceurl => "/$year/$month/$day/$p->{id}/", sourceid => $p->{id}, nooverwrite => 1 }); 
	
}

