#!/usr/bin/env perl

use strict;

# Import Foursquare
# This allows you to convert your Foursquare stream to a list of blog posts
# You need to create an app on Foursquare and authorise it to access your account first, instructions for which you'll find in the Usermesh control panel
# It's safe to run multiple times, it's sensible enough to get as much of your Foursquare stream as it can first time around
# and then each time afterwards it'll just get what's new. Stick it in your cron.

use Data::Dumper;
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use Storable qw(store retrieve);
use Data::Dumper;
use WWW::Foursquare();

use Usermesh();
use Usermesh::Helpers::Date();
use Usermesh::Plugins::Blog();

my $um = Usermesh->new();
my $date = Usermesh::Helpers::Date->new($um);
my $blog = Usermesh::Plugins::Blog->new($um);

my $config = $um->loadconfig();

# Always auth first, because we can't do anything without it
my $fs = auth();

# And then export
export($fs);

# And then convert to posts
createposts();


sub auth {
	
	my $keyfile = $um->documentroot() . "/data/foursquarekey.dat";	
	my $keydata = eval { retrieve($keyfile) } || {};
	
	if ($keydata->{client_id} eq "" or $keydata->{client_secret} eq "") {
		die "No application details found. You must authorise your connection to Foursquare through the control panel first.";
	}
	
	my $fs = WWW::Foursquare->new(%{$keydata});
	
	my $datafile = $um->documentroot() . "/data/foursquareauth.dat";	
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$fs->set_access_token($access_tokens->[0]);
	} else {
		die "No authorisation found. You must authorise your connection to Foursquare through the control panel first.";		
	}

	return $fs;	
	
}

sub export {
	
	my $fs = shift;
		
	my @statuses = ();
	my $export = 1;
	my $datafile = $um->documentroot . "/data/foursquarestream.dat";
	my $count = 200;
	my $aftertime = undef;
	
	# Open in our statuses file
	my $storedstatus = eval { retrieve($datafile) } || [];
	if ($#{$storedstatus} != -1) {
		@statuses = @{$storedstatus};
		$aftertime = $storedstatus->[$#{$storedstatus}]->{createdAt} + 1;
	}
	
	while ($export) {
	
		my $result;
		if ($aftertime) {
			print "Requesting checkins after $aftertime\n";
			$result = $fs->users()->checkins(sort => "oldestfirst", limit => $count, afterTimestamp => $aftertime);
		} else {
			print "Requesting the last $count checkins\n";
			$result = $fs->users()->checkins(sort => "oldestfirst", limit => $count);
		}
		
		my $checkins = $result->{checkins}->{items};
		
		if (@{$checkins}) {
			
			print "Got " . ($#{$checkins} + 1) . " checkins\n";
			
			# Set the aftertime to the last one we got
			$aftertime = $checkins->[$#{$checkins}]->{createdAt} + 1;
						
			push @statuses, @{$checkins};
			
		} else {
			print "No more checkins\n";
			$export = 0;
		
		}	
			
	}

	store(\@statuses, $datafile);

}

sub createposts {
	
	my $datafile = $um->documentroot . "/data/foursquarestream.dat";
	my $storedstatus = eval { retrieve($datafile) } || [];

	if ($#{$storedstatus} == -1) {
		return undef;
	}
	
	my $generated = 0;

	foreach my $item (@{$storedstatus}) {
		
		# Photo
		my ($photourl, $photo);
		if ($item->{photos}->{count} > 0) {
			$photo = $item->{photos}->{items};
			if (ref($photo) eq "ARRAY") {
				$photourl = $photo->[0]->{prefix} . $photo->[0]->{width} . "x" . $photo->[0]->{height} . $photo->[0]->{suffix};
			}
		}
		
		my $map = qq|[um showmap -name:"$item->{venue}->{name}" -lat:"$item->{venue}->{location}->{lat}" -lon:"$item->{venue}->{location}->{lng}"]|;
		
		my $saved = savepost({ timestamp => $date->unixtotimestamp($item->{createdAt}), id => $item->{id}, body => $map . "\n\n" . ($photourl ? qq|<img src="$photourl" width="$photo->[0]->{width}" height="$photo->[0]->{height}" alt="$item->{venue}->{name}">\n\n| : "") . qq|$item->{venue}->{name}\n\n$item->{shout}|, category => "Location", lat => $item->{venue}->{location}->{lat}, lon => $item->{venue}->{location}->{lng}, location => $item->{venue}->{name} });
		if ($saved) {
			$generated++;
		}
			
	}
		
	print "Generated $generated new posts.\n";	
	
}

sub savepost {
	
	my $p = shift;
	
	my ($year, $month, $day) = split(/-/, substr($p->{timestamp}, 0, 10), 3);
		
	return $blog->savepost("$year-$month-$day-$p->{id}", { type => "foursquare", date => $p->{timestamp}, categories => [ $p->{category} ], body => $p->{body}, niceurl => "/$year/$month/$day/$p->{id}/", sourceid => $p->{id}, lat => $p->{lat}, lon => $p->{lon}, location => $p->{location}, nooverwrite => 0 }); 
	
}


