
# generic functions to be used anywhere to find out handy system things

package Usermesh;

use strict;

use Cwd 'abs_path';
use File::Basename 'dirname';
use Text::Unidecode qw(unidecode);
use Data::Dumper;
use YAML::XS qw(LoadFile);

sub new {

	my $proto		= shift;
	my $class		= ref($proto) || $proto;

	my $self		= bless {}, $class;
	
	$self->{APP}	= shift;
	$self->{CONFIG} = $self->loadconfig();
	
	$self->{ADMINMENU} = [ { text => "Home", link => "/admin/", category => "", top => 1 }, { text => "Static Generator", link => "/admin/generator/", category => "" } ];

	return $self;
	
}

sub DESTROY {}

# the current web request
sub request {

	my $self		= shift;
	
	return $self->{R};
	
}

sub setrequest {
	
	my $self		= shift;
	my $request		= shift;
	
	$self->{R} = $request;
	
	return 1;
	
}

sub documentroot {
	
	my $self		= shift;
	
	if ($self->{APP}) {
		return $self->{APP}->home;
		
	} else {
		return dirname( abs_path($0) );
		
	}
	
}

sub getblock {
	
	my $self		= shift;
	my $template	= shift;
	my $p			= shift;
	
	return $self->request->render($template, partial => 1, handler => "um", replace => $p);	
	
}

sub replaceinto {
	
	my $self		= shift;
	my $template	= shift;
	my $p			= shift;

	return $self->request->render(inline => $template, partial => 1, handler => "um", replace => $p);	
	
}

sub safepath {

	my $self		= shift;
	my $path		= shift;

	my (@parts, $part, @useparts, $usepath);
	
	@parts = split(/\//, $path);

	foreach $part (@parts) {
		if ($part !~ /^\./ and $part ne "") {
			push(@useparts, $part);
		}
	}

	$usepath = join("/", @useparts);

	if ($path =~ /^\//) {
		$usepath = "/" . $usepath;
	}

	return $usepath;

}

sub addtoadminmenu {
	
	my $self		= shift;
	my $menuitem	= shift;
			
	push @{$self->{ADMINMENU}}, $menuitem;
		
	return $self->{ADMINMENU};
	
}

sub makeniceurl {

	my $self				= shift;
	my $title				= shift;
	
	$title = $self->forcelatin($title);
	
	$title =~ s/^\s+//g;
	$title =~ s/\s+$//g;
	
	$title =~ s/[^\sa-zA-Z0-9\-]//g;
	$title =~ s/\s+/-/g;
	$title =~ s/\-{1,}/-/g;
	
	return lc($title);

}

sub reverseniceurl {

	my $self				= shift;
	my $title				= shift;

	$title =~ s/\-/ /g;
	$title =~ s/\s(\w)/ \U$1/;

	return ucfirst($title);

}

sub forcelatin {
	
	my $self				= shift;
	my $string				= shift;
	
	return unidecode($string);
	
}

sub loadconfig {

	my $self				= shift;
	
	return LoadFile($self->documentroot . "/config/main.yaml");
	
}

# Load the other helpers when they're called, and they're all called through this single um object
sub AUTOLOAD {
	
	my $self = shift;
	
	our $AUTOLOAD;
	my $func = $AUTOLOAD;
	$func =~ s/.*:://;

	if (!defined $self->{uc($func)} or $func eq "form") {
	
		my $module = "Usermesh::Helpers::" . ucfirst($func);

		eval("use $module");
		$self->{uc($func)} = $module->new($self, @_);
	
	}
	
	return $self->{uc($func)};

}

1;

