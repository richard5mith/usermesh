#!/usr/bin/env perl

use strict;

# Import Twitter
# This allows you to convert your Twitter stream to a list of blog posts
# You need to create an app on Twitter and authorise it to access your account first, instructions for which you'll find in the Usermesh control panel
# It's safe to run multiple times, it's sensible enough to get as much of your Twitter stream as it can first time around (up to the 3,200 tweet API limit)
# and then each time afterwards it'll just get what's new. Stick it in your cron.

use Data::Dumper;
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

use Storable qw(store retrieve);
use Data::Dumper;
use Net::Twitter::Lite();

use Usermesh();
use Usermesh::Helpers::Date();
use Usermesh::Plugins::Blog();

my $um = Usermesh->new();
my $date = Usermesh::Helpers::Date->new($um);
my $blog = Usermesh::Plugins::Blog->new($um);

my $config = $um->loadconfig();

my $sitedomain = $config->{blogdomain};

# Always auth first, because we can't do anything without it
my $nt = auth();

# And then export
export($nt);

# And then convert to posts
createposts();

sub auth {
	
	my $keyfile = $um->documentroot() . "/data/twitterkey.dat";	
	my $keydata = eval { retrieve($keyfile) } || {};
	
	if ($keydata->{consumer_key} eq "" or $keydata->{consumer_secret} eq "") {
		die "No application details found. You must authorise your connection to Twitter through the control panel first.";
	}
	
	my $nt = Net::Twitter::Lite->new(%{$keydata});
	
	my $datafile = $um->documentroot() . "/data/twitterauth.dat";	
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$nt->access_token($access_tokens->[0]);
		$nt->access_token_secret($access_tokens->[1]);
	} else {
		die "No authorisation found. You must authorise your connection to Twitter through the control panel first.";		
	}

	return $nt;
	
}

sub export {
	
	my $nt = shift;	
	
	my @statuses = ();
	my $maxid = undef;
	my $sinceid = undef;
	my $export = 1;
	my $count = 200;
	my $datafile = $um->documentroot . "/data/twitterstream.dat";
	my $fullexport = 0;
	
	# Open in our statuses file
	my $storedstatus = eval { retrieve($datafile) } || [];
	if ($#{$storedstatus} != -1) {
		@statuses = @{$storedstatus};
		$sinceid = $storedstatus->[0]->{id};
	} else {
		$fullexport = 1;
	}
	
	print "First run, so doing a full export.\n" if ($fullexport);
	
	while ($export) {
		
		my ($statuslist);
		if (!$fullexport and $sinceid) {
			print "Requesting tweets since $sinceid\n";
			$statuslist = $nt->user_timeline({ count => $count, since_id => $sinceid, include_entities => 1 });			
		} elsif ($maxid) {
			print "Requesting tweets before $maxid\n";
			$statuslist = $nt->user_timeline({ count => $count, max_id => $maxid, include_entities => 1 });
		} else {
			print "Requesting the last $count tweets\n";
			$statuslist = $nt->user_timeline({ count => $count, include_entities => 1 });		
		}
		
		if ($#{$statuslist} != -1) {
			print "Got " . ($#{$statuslist} + 1) . " tweets\n";
			
			# Set the maxid to the last one we got
			$maxid = $statuslist->[$#{$statuslist}]->{id} - 1;
			
			# And sinceid to the first
			$sinceid = $statuslist->[0]->{id}; 
			
			# Store these ones
			if ($fullexport) {
				push @statuses, @{$statuslist};				
			} else {
				unshift @statuses, @{$statuslist};
			}
					
		} else {
			print "No more tweets\n";
			$export = 0;
		}
		
	}
	
	store(\@statuses, $datafile);

}

sub createposts {
	
	my $datafile = $um->documentroot . "/data/twitterstream.dat";
	my $storedstatus = eval { retrieve($datafile) } || [];

	if ($#{$storedstatus} == -1) {
		return undef;
	}
	
	my $generated = 0;

	foreach my $tweet (@{$storedstatus}) {
		
		# TODO: You could do maps of locations where tweets were made
		# TODO: You could also grab and images out of them and put them inline
				
		my $id = $tweet->{id};
		my $created = $tweet->{created_at};
		my $text = $tweet->{text};
		
		my $postdate = $um->date->unixtotimestamp($um->date->parsedate($created));
								
		# Skip replies and retweets
		next if ($text =~ /^@/);
		next if ($text =~ /^RT/);
		
		if (ref($tweet->{entities}->{urls}) eq "ARRAY") {
			foreach my $url (@{$tweet->{entities}->{urls}}) {	
				$text =~ s!\Q$url->{url}\E!$url->{expanded_url}!g;
			}
		}
		
		# Skip foursquare tweets, as we assume that stream is also being imported if you use it
		next if ($text =~ /4sq.com/);
		
		# And skip files containing our site domain, so we don't import tweets that link to this site
		next if ($text =~ /$sitedomain/);
		
		$text = $um->html->formathtml({ text => $text, links => 1 });
				
		my $saved = savepost({ timestamp => $postdate, id => $id, body => $text, category => "Tweets" });
		if ($saved) {
			$generated++;
		}
	
	}
	
	print "Generated $generated new posts.\n";
	
}

sub savepost {
	
	my $p = shift;
	
	my ($year, $month, $day) = split(/-/, substr($p->{timestamp}, 0, 10), 3);
		
	return $blog->savepost("$year-$month-$day-$p->{id}", { type => "twitter", date => substr($p->{timestamp}, 0, 19), categories => [ $p->{category} ], body => $p->{body}, niceurl => "/$year/$month/$day/$p->{id}/", sourceid => $p->{id}, nooverwrite => 1 }); 
	
}


