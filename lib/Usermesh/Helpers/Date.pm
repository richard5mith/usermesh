
package Usermesh::Helpers::Date;

use strict;

use DateTime;
use Time::Local;
use Date::Manip qw(ParseDate);
use DateTime::TimeZone;

sub new {

	my $proto				= shift;
	my $class				= ref($proto) || $proto;

	my $self				= bless {}, $class;

	$self->{UM}				= shift;
	
	$self->{DT}				= DateTime->now();
	$self->{TZ}				= new DateTime::TimeZone(name => "local");
	
	$self->{USERTZ}			= "local";

	return $self;

}

sub um {

	my $self = shift;	
	
	return $self->{UM};
	
}

sub settimezone {
	
	my $self				= shift;
	$self->{USERTZ}			= shift;

	return 1;

}

sub formatdate {

	my $self				= shift;
	my $value				= shift;
	my $format				= shift;
	my $zone				= shift || $self->{USERTZ} || "local";
	my $relative			= shift;
	
	my ($mon, $day, $year, $hour, $min, $sec, $shortday, $shortmon, $shorthour, $shortmin, $shortsec, $shorthourtw, $hourtw, $ts, $unixtime, $now, $secondsapart, $relstring);

	if (length($value) == 10 and $value !~ /-/) {
		$value = $self->unixtotimestamp($value, "combined");
	}

	if ($value eq "") {
		$value = "00000000000000";
	}

	$value =~ s/\D//g;

	if ($format eq "") {
		$format = "M1 D1, h2:m2";
	}

	$value .= "0" x (14 - length($value));
	if ($value eq "00000000000000") {
		return "";
	}
	
	# Return a relative human readable date if needed
	if ($relative == 1) {
		$now = time;
		$secondsapart = $now - $self->timestamptounix($value);
		$relstring = $self->formatrelative($secondsapart);
		
		return $relstring if (defined $relstring);
	}

	# Set the time object to the time passed in
	if ($zone ne "local") {
		# Move it to a different zone
		$self->{DT}->set_time_zone("UTC");

		$self->{DT}->set(	day		=>	$self->now($self->timestamptounix($value))->[0],
							month	=>	$self->now($self->timestamptounix($value))->[1],
							year	=>	$self->now($self->timestamptounix($value))->[2],
							hour	=>	$self->now($self->timestamptounix($value))->[3],
							minute	=>	$self->now($self->timestamptounix($value))->[4],
							second	=>	$self->now($self->timestamptounix($value))->[5]);

		eval {
			$self->{DT}->set_time_zone($zone);
		};
		warn $@ if ($@);

		# Now get the unixtime from it again
		$unixtime = $self->{DT}->epoch + $self->{DT}->offset;

		# And convert it back to timestamp
		$value = $self->unixtotimestamp($unixtime, "combined");

	} else {
		$unixtime = $self->timestamptounix($value);
	}

	my @months = ("January","February","March","April","May","June","July","August","September","October","November","December");
	my @shortmonths = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	my @daysuffix = ("st","nd","rd","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","th","st","nd","rd","th","th","th","th","th","th","th","st");
	my @days = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
	my @shortdays = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");

	$mon = substr($value,4,2);
	$day = substr($value,6,2);
	$year = substr($value,0,4);
	$hour = substr($value,8,2);
	$min = substr($value,10,2);
	$sec = substr($value,12);

	$ts = "am";
	$hourtw = $hour;

	if ($hour > 12) {
		$hourtw = $hour - 12;
		$ts = "pm";
	}

	if ($hour == 12) {
		$ts = "pm";
	}

	if ($hour == 0) {
		$hourtw = 12;
	}

	if ($hourtw < 10 and $hourtw !~ /^0/) {
		$hourtw = "0" . $hourtw;
	}

	$shortday = $day; $shortday =~ s/^0+//;
	$shortmon = $mon; $shortmon =~ s/^0+//;
	$shorthour = $hour; $shorthour =~ s/^0+//;
	$shortmin = $min; $shortmin =~ s/^0+//;
	$shortsec = $sec; $shortsec =~ s/^0+//;
	$shorthourtw = $hourtw; $shorthourtw =~ s/^0+//;

	# Work out the day of the week
	my (undef, undef, undef, undef, undef, undef, $weekday, undef, undef) = gmtime($unixtime);

	my %formats = (	"M1"	=>	$shortmon,
					"M2"	=>	$mon,
					"M3"	=>	$shortmonths[$mon - 1],
					"M4"	=>	$months[$mon - 1],
					"D1"	=>	$shortday,
					"D2"	=>	$day,
					"D3"	=>	$shortdays[$weekday],
					"D4"	=>	$days[$weekday],
					"Y1"	=>	substr($year, -2, 2),
					"Y2"	=>	$year,
					"h1"	=>	$shorthour,
					"h2"	=>	$hour,
					"h3"	=>	$shorthourtw,
					"h4"	=>	$hourtw,
					"m1"	=>	$shortmin,
					"m2"	=>	$min,
					"s1"	=>	$shortsec,
					"s2"	=>	$sec,
					"ds"	=>	$daysuffix[$day - 1],
					"ts"	=>	$ts);

	my ($formatitem, $value);
	my @formatlist = keys(%formats);
	foreach $formatitem (@formatlist) {
		$value = $formats{$formatitem};
		$format =~ s/\Q$formatitem\E/$value/g;
	}

	return $format;

}

sub timestamptounix {

	my $self				= shift;
	my $timestamp			= shift;

	my ($year, $month, $day, $hour, $minute, $second, $invalid);
	my @days = qw(31 28 31 30 31 30 31 31 30 31 30 31);

	if (length($timestamp) == 19) {
		$timestamp =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])(?:T|\s)([0-9][0-9]):([0-9][0-9]):([0-9][0-9])/;

		$year = $1;
		$month = ($2 - 1);
		$day = $3;
		$hour = $4;
		$minute = $5;
		$second = $6;
	} elsif (length($timestamp) == 14) {
	    $timestamp =~ /^([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])/;

		$year = $1;
		$month = ($2 - 1);
		$day = $3;
		$hour = $4;
		$minute = $5;
		$second = $6;
	} elsif (length($timestamp) == 10) {
		$timestamp =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])/;

		$year = $1;
		$month = ($2 - 1);
		$day = $3;
		$hour = 0;
		$minute = 0;
		$second = 0;
	} elsif (length($timestamp) == 8) {
		$timestamp =~ /^([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])/;

		$year = $1;
		$month = ($2 - 1);
		$day = $3;
		$hour = 0;
		$minute = 0;
		$second = 0;
	} else {
		$invalid = 1;
	}

	if ($month < 0) {
		$month = 0;
	}

	if ($day > 0 and $month >= 0 and $year > 0 and $hour >= 0 and $minute >= 0 and $second >= 0 and !$invalid) {
		if ($self->isleapyear($year)) {
			$days[1] = 29;
		}
		if ($day > $days[$month]) {
			$day = $days[$month];
		}
		if ($year < 1902) {
			$year = 1902;
		}

		return timelocal($second, $minute, $hour, $day, $month, $year);
	} else {
		return 0;
	}
}

sub unixtotimestamp {

	my $self				= shift;
	my $unixtime			= shift || time;
	my $type				= shift;
	
	if (!defined $type) {
		$type = "timestamp";
	}

	# Get the current date
	my ($second, $minute, $hour, $dayofmonth, $month, $year, $weekday, $dayofyear, $lsdst) = gmtime($unixtime);

	$month++;
	$year += 1900;
	if ($hour < 10) { $hour = "0$hour" };
	if ($minute < 10) { $minute = "0$minute" };
	if ($second < 10) { $second = "0$second" };
	if ($month < 10) { $month = "0$month" };
	if ($dayofmonth < 10) { $dayofmonth = "0$dayofmonth" };

	if ($type eq "combined") {
		return "$year$month$dayofmonth$hour$minute$second";
	} elsif ($type eq "iso") {
		return "$year-$month-$dayofmonth";
	} else {
		return "$year-$month-$dayofmonth $hour:$minute:$second";
	}

}

sub now {

	my $self				= shift;
	my $time				= shift;

	if (!defined $time) {
		$time = time;
	}

	# Returns the current date
	my ($nsecond, $nminute, $nhour, $ndayofmonth, $nmonth, $nyear, $nweekday, $ndayofyear, $nlsdst) = gmtime($time);
	my $nrealmonth = $nmonth + 1;
	$nyear = $nyear + 1900;
	if ($nweekday == 0) { $nweekday = 7 };	# Make sunday = 7, not 0

	return [ ($ndayofmonth, $nrealmonth, $nyear, $nhour, $nminute, $nsecond, $nweekday, $ndayofyear, $nlsdst) ];

}

sub valuestounix {

	my $self				= shift;
	my $mday				= shift;
	my $mon					= shift;
	my $year				= shift;
	my $hours				= shift;
	my $min					= shift;
	my $sec					= shift;

	return timegm($sec, $min, $hours, $mday, $mon, $year);

}

sub parsedate {

	my $self				= shift;
	my $value				= shift;

	my $return = ParseDate($value);

	if (!$return) {
		return undef;
	} else {
		$return =~ s/\D//g;
		return $self->timestamptounix($return);
	}

}

sub isleapyear {

	my $self				= shift;
	my $year				= shift;

	if($year % 4 == 0) {
		if($year % 100 != 0) {
			return 1;
		} else {
			if ($year % 400 == 0) {
				return 1;
			}
		}
	}

	return 0;
}

sub formatrelative {
	
	my $self				= shift;
	my $value				= shift;

	my ($offset);

	if ($value >= 0 and $value < 60) {
		if ($value == 1) {
			return "$value second ago";			
		} else {
			return "$value seconds ago";
		}
		
	} elsif ($value >= 60 and $value < 3600) {
		$offset = int($value / 60);
		
		if ($offset == 1) {
			return "$offset minute ago";
		} else {
			return "$offset minutes ago";			
		}

	} elsif ($value >= 3600 and $value < 14400) {
		$offset = int($value / 60 / 60);
		
		if ($offset == 1) {
			return "$offset hour ago";
		} else {
			return "$offset hours ago";
		}
		
	} else {
		return undef;
		
	}
	
}

1;
