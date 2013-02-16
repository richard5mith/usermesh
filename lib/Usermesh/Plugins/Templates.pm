
package Usermesh::Plugins::Templates;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;

sub register {
	
	my $self = shift;
	my $app = shift;
	
	# Add "mine" handler
	$app->renderer->add_handler(um => sub {
			
		my $renderer = shift;
		my $c = shift;
		my $output = shift;
		my $options = shift;

		$self->{UM} = $c;
				
		# Check for one time use inline template
		my $inline = $options->{inline};
		
		# Check for absolute template path
		my $path = $renderer->template_path($options);

		$$output = getblock($c, $path, $c->stash->{replace}, $inline);
		
		# And return true if something has been rendered or false otherwise
		return 1;
	});
	
}

sub new {
	
	my $proto		= shift;
	my $class		= ref($proto) || $proto;

	my $self		= bless {}, $class;
	
	$self->{UM}		= shift;
		
	return $self;	
	
}

sub um {
	
	my $self = shift;

	return $self->{UM};
	
}

sub getblock {
	
	my $self			= shift;
	my $block			= shift;
	my $replace			= shift;
	my $inline			= shift;

	if (defined $block and $block !~ /^\//) {
		$block = $self->um->documentroot . "/templates/" . $block . ".html.um";
	}
	
	my $template;
	if ($inline) {
		$template = $inline;
		
	} elsif ($block) {

		local $_;
		$template = "";
		if (-e $self->um->safepath($block)) {
			open(IN, $self->um->safepath($block));
			while(<IN>) {
				$template .= $_;
			}
			close(IN);
		} else {
			return 0;
		}

	}

	# Replace variables
	$template = replaceinto($self, $template, $replace);

	# And parse for other things
	$template = parse($self, $template);
	
	$template =~ s/\r$//g;
	$template =~ s/\n$//g;
	
	return $template;
	
}

sub replaceinto {
	
	my $self				= shift;
	my $input				= shift;
	my $pairs				= shift;

	my (@parts, $part, $field, $value, $dateformat, @extra);

	@parts = split m/(%[\w\.\:\d\s\/\,_]+?%)/s, $input;
	
	my $out = "";
	foreach $part (@parts) {
		if (substr($part, 0, 1) eq "%" and substr($part, -1, 1) eq "%") {
			$field = substr($part, 1, -1);
			
			if ($field =~ /:/) {
				($value, @extra) = split(/:/, $field);
				$dateformat = join(":", @extra);

				if (exists $pairs->{lc($value)}) {
					$out .= $self->um->date->formatdate($pairs->{lc($value)}, $dateformat);
				} else {
					$out .= "%" . $field . "%";
				}

			} else {
				if (exists $pairs->{lc($field)}) {
					$out .= $pairs->{lc($field)} || "";
				} else {
					$out .= "%" . uc($field) . "%";
				}
			}
		} else {
			$out .= $part;
		}
	}

	return $out;	
	
}

# [um function -name:"hello" -age:"25"]
sub parse {

	my $self				= shift;
	my $input				= shift;

	my @parts = split m/(\[um .*?\])/s, $input;
	
	my ($output);

	local $1;
	foreach my $part (@parts) {
		if ($part =~ /\[(um .*?)\]/) {
			my (undef, $cmd, $params) = split(/ /, $1, 3);

			$params = {} if (not defined $params);
			my %paramhash = ();
			my @new = ();
			push(@new, $+) while $params =~ m{
				  "([^\"\\]*(?:\\.[^\"\\]*)*)"\s?			# This is a value in inverted commas
				| (\-[a-z]+:)?								# This is a field name
			}gx;

			my $nextkey;
			while (@new) {
				my $item = shift(@new);

				next if (!$item);

				if (substr($item, 0, 1) eq "-" and substr($item, -1, 1) eq ":") {
					$nextkey = substr($item, 1, -1);
				} else {
					$paramhash{$nextkey} = $item;
				}
			}

			if (defined $self->um->{TEXTPLUGINS}->{$cmd}) {
				$output .= $self->um->{TEXTPLUGINS}->{$cmd}($self, $self->um, \%paramhash);
			} else {
				$output .= $self->$cmd(\%paramhash);
				
			}
			
		} else {
			$output .= $part;
		}
	}

	return $output;

}

1;
