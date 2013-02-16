
package Usermesh::Helpers::Form;

use strict;

use Data::Dumper;
use HTML::Entities qw(encode_entities);

sub new {

	my $proto			= shift;
	my $class			= ref($proto) || $proto;

	my $self			= bless {}, $class;
	
	$self->{UM}			= shift;
	
	$self->create(@_);

	return $self;
}

sub um {

	my $self = shift;	
	
	return $self->{UM};
	
}

sub default {

	return;

}

sub create {

	my $self				= shift;
	my $name				= shift;
	my $fields				= shift;
	my $action				= shift;
	my $method				= shift;
	my $id					= shift;
	
	$self->{FORM} = {};
	
	if (!defined $method) {
		$method = "POST";
	}

	if (defined($fields)) {

		if (ref($fields) eq "ARRAY") {
			$self->{FORM}->{options} = { fieldlist => $fields, action => $action, method => $method, sticky => 1, wizard => 0 };
		} elsif (ref($fields) eq "HASH") {
			$self->{FORM}->{options} = { fieldlist => $fields, action => $action, method => $method, sticky => 1, wizard => 1 };
		} else {
			die "Fields must be an array of field names or a keyarray of wizard steps, each being an array of field names for that step.";
		}

	}

	# Set the defaults
	my @monthlist = qw(January February March April May June July August September October November December);

	$self->{FORM}->{options}->{formid} = $id;
	$self->{FORM}->{options}->{name} = $name;
	$self->{FORM}->{options}->{daylist} = { map { $_ => $_ } (1..31) };
	$self->{FORM}->{options}->{monthlist} = { map { ($_+1) => $monthlist[$_] } 0..$#monthlist };
	$self->{FORM}->{options}->{yearlist} = { map { $_ => $_ } (2013..2016) };
	$self->{FORM}->{options}->{hourlist} = { map { sprintf("%02d", $_) => sprintf("%02d", $_) } (0..23) };
	$self->{FORM}->{options}->{minutelist} = { map { sprintf("%02d", $_) => sprintf("%02d", $_) } (0..59) };
	$self->{FORM}->{options}->{secondlist} = { map { sprintf("%02d", $_) => sprintf("%02d", $_) } (0..59) };

	$self->defaulttemplates();
	$self->{FORM}->{templates}->{joinitemlist} = "";

	$self->{FORM}->{default} = "text";
	$self->{FORM}->{options}->{enableutf8} = 1;
	
	return $self;

}

sub action {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{action};
	} else {
		$self->{FORM}->{options}->{action} = $value;
		return 1;
	}

}

sub method {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{method};
	} else {
		$self->{FORM}->{options}->{method} = $value;
		return 1;
	}

}

sub wizard {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{wizard};
	} else {
		$self->{FORM}->{options}->{wizard} = $value;
		return 1;
	}

}

sub enctype {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{enctype};
	} else {
		$self->{FORM}->{options}->{enctype} = $value;
		return 1;
	}

}

sub fields {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{fieldlist};
	} else {
		if (ref($value) eq "ARRAY") {
			$self->{FORM}->{options}->{fieldlist} = $value;
			$self->{FORM}->{options}->{wizard} = 0;
		} elsif (ref($value) eq "HASH") {
			$self->{FORM}->{options}->{fieldlist} = $value;
			$self->{FORM}->{options}->{wizard} = 1;
		} else {
			die "Fields must be an array of field names or a keyarray of wizard steps, each being an array of field names for that step.";
		}
		return 1;
	}

}

sub addfield {

	my $self				= shift;
	my $value				= shift;

	if (defined $value) {
		if (ref($value) eq "ARRAY") {
			push(@{$self->{FORM}->{options}->{fieldlist}}, @{$value});
		} else {
			push(@{$self->{FORM}->{options}->{fieldlist}}, $value);
		}

		return 1;
	} else {
		return 0;
	}

}

sub removefield {
	
	my $self				= shift;
	my $value				= shift;
	
	my ($field, @new);
	
	if (defined $value) {
		
		foreach $field (@{$self->{FORM}->{options}->{fieldlist}}) {
			if ($field ne $value) {
				push @new, $field;
			}
		}
		
		@{$self->{FORM}->{options}->{fieldlist}} = @new;

		return 1;
		
	} else {
		return 0;
	}

}

# head, row, foot, page, starterrorlist, joinerrorlist, enderrorlist, starterror, enderror
# startlabel, endlabel, starthelp, endhelp, startitem, enditem, joinitemlist, required
sub template {

	my $self				= shift;
	my $template			= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{templates}->{$template};
	} else {
		$self->{FORM}->{templates}->{$template} = $value;
		return 1;
	}

}

sub sticky {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{sticky};
	} else {
		$self->{FORM}->{options}->{sticky} = $value;
		return 1;
	}

}

sub showerrors {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{showerrors};
	} else {
		$self->{FORM}->{options}->{showerrors} = $value;
		return 1;
	}

}

# Sets a default type for an un-typed field
sub defaulttype {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{default};
	} else {
		$self->{FORM}->{default} = $value;
		return 1;
	}

}

sub defaulterror {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{defaulterror};
	} else {
		$self->{FORM}->{defaulterror} = $value;
		return 1;
	}

}

sub type {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{type};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{type} = $value;
		return 1;
	}

}

sub label {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{label};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{label} = $value;
		return 1;
	}

}

sub noname {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{noname};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{noname} = $value;
		return 1;
	}

}

sub rowtemplate {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{rowtemplate};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{rowtemplate} = $value;
		return 1;
	}

}

sub required {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{required};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{required} = $value;
		return 1;
	}

}

sub help {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{help};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{help} = $value;
		return 1;
	}

}

sub daylist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{daylist} || $self->{FORM}->{options}->{daylist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{daylist} = $value;
		return 1;
	}

}


sub monthlist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{monthlist} || $self->{FORM}->{options}->{monthlist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{monthlist} = $value;
		return 1;
	}

}

sub yearlist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{yearlist} || $self->{FORM}->{options}->{yearlist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{yearlist} = $value;
		return 1;
	}

}

sub hourlist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{hourlist} || $self->{FORM}->{options}->{hourlist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{hourlist} = $value;
		return 1;
	}

}

sub minutelist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{minutelist} || $self->{FORM}->{options}->{minutelist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{minutelist} = $value;
		return 1;
	}

}

sub secondlist {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{secondlist} || $self->{FORM}->{options}->{secondlist};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{secondlist} = $value;
		return 1;
	}

}

# Get/Set a field property, like size, rows, cols etc
sub properties {

	my $self				= shift;
	my $field				= shift;
	my $properties			= shift;
	my $step				= shift;

	my ($item);

	if (ref($properties) eq "HASH") {
		foreach $item (keys(%{$properties})) {
			$self->$item($field, $properties->{$item}, $step);
		}

	} else {
		die "You must pass a keyarray of properties and values you wish to set.";
	}

	return 1;

}

sub p {

	my $self				= shift;

	return $self->properties(@_);

}

sub id {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{id};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{id} = $value;
		return 1;
	}

}

sub enableutf8 {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if ($field eq "") {
		$self->{FORM}->{options}->{enableutf8} = $value;	
		
	} else {
		
		if (!defined $value) {
			return $self->{FORM}->{"fields$step"}->{$field}->{enableutf8};
		} else {
			$self->{FORM}->{"fields$step"}->{$field}->{enableutf8} = $value;
			return 1;
		}

	}
}

sub formid {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{formid};
	} else {
		$self->{FORM}->{options}->{formid} = $value;
		return 1;
	}

}

sub formname {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{formname};
	} else {
		$self->{FORM}->{options}->{formname} = $value;
		return 1;
	}

}

sub formclass {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{formclass};
	} else {
		$self->{FORM}->{options}->{formclass} = $value;
		return 1;
	}

}

sub resultbox {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{FORM}->{options}->{resultbox};
	} else {
		$self->{FORM}->{options}->{resultbox} = $value;
		return 1;
	}

}

sub class {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{class};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{class} = $value;
		return 1;
	}

}

sub size {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{size};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{size} = $value;
		return 1;
	}

}

sub maxlength {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{maxlength};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{maxlength} = $value;
		return 1;
	}

}

sub rows {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{rows};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{rows} = $value;
		return 1;
	}

}

sub cols {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{cols};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{cols} = $value;
		return 1;
	}

}

sub width {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{width};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{width} = $value;
		return 1;
	}

}

sub height {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{height};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{height} = $value;
		return 1;
	}

}

sub disabled {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{disabled};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{disabled} = $value;
		return 1;
	}

}

sub readonly {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{readonly};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{readonly} = $value;
		return 1;
	}

}

sub src {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{src};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{src} = $value;
		return 1;
	}

}

sub border {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{border};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{border} = $value;
		return 1;
	}

}

sub event {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{event};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{event} = $value;
		return 1;
	}

}

sub style {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{style};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{style} = $value;
		return 1;
	}

}

sub includetime {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{includetime};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{includetime} = $value;
		return 1;
	}

}

sub showblank {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{showblank};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{showblank} = $value;
		return 1;
	}

}

sub custom {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{custom};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{custom} = $value;
		$self->{FORM}->{"fields$step"}->{$field}->{type} = "custom";
		return 1;
	}

}

sub forcevalue {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{forcevalue};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{forcevalue} = $value;
		return 1;
	}

}

sub value {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{value};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{value} = $value;
		return 1;
	}

}

sub values {

	my $self				= shift;
	my $values				= shift;
	my $step				= shift;

	my ($item);

	if (ref($values) eq "HASH") {

		foreach $item (keys(%{$values})) {
			$self->{FORM}->{"fields$step"}->{$item}->{value} = $values->{$item};
		}

	} else {
		die "Values must be a keyarray that associates each field name with the value to use.";
	}


}

sub multiple {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{multiple};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{multiple} = $value;
		return 1;
	}

}

sub listvalueonly {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{listvalueonly};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{listvalueonly} = $value;
		return 1;
	}

}

# array of keyarrays
sub options {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	my (@values, $item);

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{options};
	} else {
		if (ref($value) eq "ARRAY") {
			if (ref($value->[0]) eq "HASH") {
				$self->{FORM}->{"fields$step"}->{$field}->{options} = $value;
			} else {
				foreach $item (@{$value}) {
					push(@values, { $item => $item });
				}
				$self->{FORM}->{"fields$step"}->{$field}->{options} = \@values;
			}
		} else {
			die "Options must either be an array of values or an array of keyarrays.";
		}
		return 1;
	}

}

# Choose a field validation type or provide a regexp
sub validation {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	my ($key);

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{validation};
	} else {
		if (ref($value) eq "HASH") {
			foreach $key (keys(%{$value})) {
				if ($key ne "") {
					push(@{$self->{FORM}->{"fields$step"}->{$field}->{validation}}, $key);
					push(@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}}, $value->{$key});
				} else {
					die "Validation method cannot be blank.";
				}
			}

			return 1;
		} elsif (ref($value) eq "ARRAY") {
			foreach $key (@{$value}) {
				push(@{$self->{FORM}->{"fields$step"}->{$field}->{validation}}, $key);
				push(@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}}, "");
			}

			return 1;
		} else {
			if ($value ne "") {
				push(@{$self->{FORM}->{"fields$step"}->{$field}->{validation}}, $value);
				push(@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}}, "");
				return 1;
			} else {
				die "Validation method cannot be blank.";
			}
		}
	}

}

sub clearvalidation {

	my $self				= shift;
	my $field				= shift;
	my $step				= shift;

	@{$self->{FORM}->{"fields$step"}->{$field}->{validation}} = ();
	@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}} = ();

	return 1;

}

sub drawfunction {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{drawfunction};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{drawfunction} = $value;
		return 1;
	}

}

sub placeholder {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;
	my $step				= shift;

	if (!defined $value) {
		return $self->{FORM}->{"fields$step"}->{$field}->{placeholder};
	} else {
		$self->{FORM}->{"fields$step"}->{$field}->{placeholder} = $value;
		return 1;
	}

}

sub content {

	my $self				= shift;
	my $step				= shift;
	my $surround			= shift;
	
	my ($html, $method, $action, $headtemplate, $rowtemplate, $foottemplate, $size, $submitlabel, $item, $value, $rows, $cols, $label, $submitname);
	my ($buttons, @fieldprops, $fieldprop, $fieldproplist, $eventname, $option, $selected, $optionvalue, $optiontext, $errorlist, $errors);
	my (@fieldlist, @cgivalues, $help, @items, $button, $autoparams, $field, %ftypes, $fields, $newrow, $checkboxid);

	if ($self->{FORM}->{options}->{wizard} == 1 and $step eq "") {
		die "You must specify the wizard step to render.";
	}

	%ftypes = (
				"text"		=>	[ qw(size maxlength style event class id disabled readonly placeholder) ],
				"password"	=>	[ qw(size style event class id disabled readonly) ],
				"file"		=>	[ qw(size style event class id disabled) ],
				"textarea"	=>	[ qw(rows cols style event class id disabled) ],
				"checkbox"	=>	[ qw(style event class id disabled) ],
				"radio"		=>	[ qw(style event class id disabled) ],
				"select"	=>	[ qw(size style event class id disabled) ],
				"picture"	=>	[ qw(width height src border style event class id disabled) ],
				"button"	=>	[ qw(style event class id disabled) ],
				"submit"	=>	[ qw(style event class id disabled) ],
				"reset"		=>	[ qw(style event class id disabled) ],
				"hidden"	=>	[ qw(id) ],
				"infotext"	=>	[ qw(id) ],
				"date"		=>	[ qw(class) ],
				
				);

	$method = $self->{FORM}->{options}->{method};
	$action = $self->{FORM}->{options}->{action};

	# Template Fun
	# Head
	$headtemplate = $self->{FORM}->{templates}->{head};
	$rowtemplate = $self->{FORM}->{templates}->{row};
	$foottemplate = $self->{FORM}->{templates}->{foot};
	my $fieldonlytemplate = $self->{FORM}->{templates}->{fieldonly};

	if ($surround) {
		$surround = $self->um->getblock($surround);
	}
	
	# Output Header
	$headtemplate = $self->um->replaceinto($headtemplate, { method => $method, action => $action, enctype => ($self->{FORM}->{options}->{enctype} eq "" ? "" : qq| enctype="| . $self->{FORM}->{options}->{enctype} . qq|"|), id => ($self->{FORM}->{options}->{formid} eq "" ? "" : qq| id="| . $self->{FORM}->{options}->{formid} . qq|"|), class => ($self->{FORM}->{options}->{formclass} eq "" ? "" : qq| class="| . $self->{FORM}->{options}->{formclass} . qq|"|), name => ($self->{FORM}->{options}->{formname} eq "" ? "" : qq| name="| . $self->{FORM}->{options}->{formname} . qq|"|) });
	$html .= $headtemplate;

	if ($self->{FORM}->{options}->{showerrors} != 0) {
		if (ref($self->{FORM}->{errorlist}) eq "HASH") {
			$errorlist = $self->{FORM}->{errorlist};
		} else {
			$errorlist = $self->validate($step);
		}
	}

	if ($self->{FORM}->{options}->{wizard} == 1) {
		@fieldlist = @{$self->{FORM}->{options}->{fieldlist}->{$step}};
	} else {
		@fieldlist = @{$self->{FORM}->{options}->{fieldlist}};
	}

	# Output Each Field
	$checkboxid = 0;
	foreach $field (@fieldlist) {

		$item = "";
		$help = "";

		$label = $self->{FORM}->{"fields$step"}->{$field}->{label} || ucfirst($field);

		if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "") {
			$self->{FORM}->{"fields$step"}->{$field}->{type} = $self->{FORM}->{default};
		}

		# If the form is sticky
		if ($self->{FORM}->{options}->{sticky} == 1 and $self->{FORM}->{"fields$step"}->{$field}->{forcevalue} == 0) {
			if ($self->{FORM}->{"fields$step"}->{$field}->{type} ne "date") {
				# If the field is defined in the cgi params
				if (!defined($self->um->request->param($field))) {
					# It's not, so use the value that's been set elsewhere
					$value = $self->{FORM}->{"fields$step"}->{$field}->{value};
				} else {
					# It is, so use the cgi param as the value
					@cgivalues = $self->um->request->param($field);
					if ($#cgivalues != 0 or grep(/^$self->{FORM}->{"fields$step"}->{$field}->{type}$/, qw(checkbox select radio))) {
						$value = [ @cgivalues ];
					} else {
						$value = $cgivalues[0];
					}
				}

			} else {
				if (defined($self->um->request->param("$field-year")) or defined($self->um->request->param("$field-month")) or defined($self->um->request->param("$field-day"))) {
					if ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 1) {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute"));
					} elsif ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 2) {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute")) . ":" . sprintf("%02d", $self->um->request->param("$field-second"));
					} else {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day"));
					}
				} else {
					# It's not, so use the value that's been set elsewhere
					$value = $self->{FORM}->{"fields$step"}->{$field}->{value};
				}
			}
		} else {
			$value = $self->{FORM}->{"fields$step"}->{$field}->{value};
		}
		
		# Calculate all the field properties
		@fieldprops = ();
		foreach $fieldprop (@{$ftypes{$self->{FORM}->{"fields$step"}->{$field}->{type}}}) {
			if ($fieldprop eq "event") {
				foreach $eventname (keys(%{$self->{FORM}->{"fields$step"}->{$field}->{$fieldprop}})) {
					push(@fieldprops, qq|$eventname="| . $self->{FORM}->{"fields$step"}->{$field}->{$fieldprop}->{$eventname} . qq|"|);
				}

			} elsif ($fieldprop eq "disabled") {
				push(@fieldprops, "disabled") if ($self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} == 1);

			} else {
				# Set some defaults
				if ($fieldprop eq "size" and $self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} eq "") {
					if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "text") {
						$self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} = 20;
					}
				} elsif ($fieldprop eq "rows" and $self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} eq "") {
					$self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} = 2;
				} elsif ($fieldprop eq "cols" and $self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} eq "") {
					$self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} = 20;
				}
				push(@fieldprops, qq|$fieldprop="| . $self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} . qq|"|) if ($self->{FORM}->{"fields$step"}->{$field}->{$fieldprop} ne "");
			}
		}

		$fieldproplist = join(" ", @fieldprops);

		# Render each type
		if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "text") {
			$value = encode_entities($value);

			$item = qq|<input type="text" name="$field" value="$value" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "password") {
			$value = encode_entities($value);

			$item = qq|<input type="password" name="$field" value="$value" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "textarea") {
			$value = encode_entities($value);

			$item = qq|<textarea name="$field" $fieldproplist>$value</textarea>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "checkbox") {
			@items = ();
			foreach $option (@{$self->{FORM}->{"fields$step"}->{$field}->{options}}) {
				($optionvalue) = keys(%{$option});
				($optiontext) = CORE::values(%{$option});
				
				if ((ref($value) eq "ARRAY" and grep(/^\Q$optionvalue\E$/, @{$value})) or $optionvalue eq $value) {				
					push(@items, qq|<label class="checkbox"><input type="checkbox" name="$field" value="$optionvalue" id="check$checkboxid" $fieldproplist checked> $optiontext</label>|);
					$checkboxid++;
				} else {
					push(@items, qq|<label class="checkbox"><input type="checkbox" name="$field" value="$optionvalue" id="check$checkboxid" $fieldproplist> $optiontext</label>|);
					$checkboxid++;
				}
			}

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &{$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}}(\@items);
			} else {
				$item = join($self->{FORM}->{templates}->{joinitemlist}, @items);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "radio") {
			@items = ();
			foreach $option (@{$self->{FORM}->{"fields$step"}->{$field}->{options}}) {
				($optionvalue) = keys(%{$option});
				($optiontext) = CORE::values(%{$option});

				$optiontext = encode_entities($optiontext);				
	
				if ((ref($value) eq "ARRAY" and grep(/^\Q$optionvalue\E$/, @{$value})) or $optionvalue eq $value) {
					push(@items, qq|<label class="radio"><input type="radio" name="$field" value="$optionvalue" id="radio$checkboxid" $fieldproplist checked> $optiontext</label>|);
					$checkboxid++;					
				} else {
					push(@items, qq|<label class="radio"><input type="radio" name="$field" value="$optionvalue" id="radio$checkboxid" $fieldproplist> $optiontext</label>|);
					$checkboxid++;					
				}
			}

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}(\@items);
			} else {
				$item = join($self->{FORM}->{templates}->{joinitemlist}, @items);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "select") {
			if ($self->{FORM}->{"fields$step"}->{$field}->{multiple} eq "1") {
				$item = qq|<select name="$field" $fieldproplist multiple>|;
			} else {
				$item = qq|<select name="$field" $fieldproplist>|;
			}
			foreach $option (@{$self->{FORM}->{"fields$step"}->{$field}->{options}}) {
				($optionvalue) = keys(%{$option});
				($optiontext) = CORE::values(%{$option});

				$optiontext = encode_entities($optiontext);

				if ((ref($value) eq "ARRAY" and grep(/^$optionvalue$/, @{$value})) or $optionvalue eq $value) {
					$item .= qq|<option value="$optionvalue" selected>$optiontext</option>|;
				} else {
					$item .= qq|<option value="$optionvalue">$optiontext</option>|;
				}
			}
			$item .= qq|</select>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "picture") {
			$item = qq|<input type="image" name="$field" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "file") {
			$item = qq|<input type="file" name="$field" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "button") {
			$item = "";
			$button = qq|<input type="button" name="$field" value="$label" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$button = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($button);
			}

			$buttons .= $button . " ";

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "submit") {

			my $namefield;
			if ($self->{FORM}->{"fields$step"}->{$field}->{noname}) {
				$namefield = "";
			} else {
				$namefield = $field;
			}
			
			my $class = $self->{FORM}->{"fields$step"}->{$field}->{class};
			if ($class eq "") {
				$class = "formbutton";
			}
			$item = "";
			if ($method ne "AJAX") {
				$button = qq|<input type="submit" name="$namefield" value="$label" class="btn $class" $fieldproplist>|;
			} else {
				$button = qq|<input type="submit" name="$namefield" value="$label" class="btn $class" onclick="ajaxsubmitform('$self->{FORM}->{options}->{formid}','$action','$self->{FORM}->{options}->{resultbox}'); return false;" $fieldproplist>|;
			}

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$button = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($button);
			}

			$buttons .= $button . " ";

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "reset") {
			$item = "";
			$button = qq|<input type="reset" name="$field" value="$label" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$button = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($button);
			}

			$buttons .= $button . " ";

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "hidden") {
			$item = "";

			$button = qq|<input type="hidden" name="$field" value="$value" $fieldproplist>|;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$button = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($button);
			}

			$buttons .= $button;

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "date") {
			$item = $self->selectdate($value, $field, $self->{FORM}->{"fields$step"}->{$field}->{includetime}, $self->{FORM}->{"fields$step"}->{$field}->{showblank}, $fieldproplist);

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "custom") {

			$item = $self->{FORM}->{"fields$step"}->{$field}->{custom};

			$item =~ s/%FIELD%/$field/;
			$item =~ s/%VALUE%/$value/;

			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "sectionhead") {

			$html .= $self->um->replaceinto($self->{FORM}->{templates}->{sectionhead}, { label => $label, help => $self->{FORM}->{"fields$step"}->{$field}->{help}, id => $self->{FORM}->{"fields$step"}->{$field}->{id} || $field });

			$item = "";

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "seperator") {

			$html .= $self->um->replaceinto($self->{FORM}->{templates}->{seperator}, { id => $self->{FORM}->{"fields$step"}->{$field}->{id} || $field });

			$item = "";

		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "infotext") {
		
			$item = qq|<b>| . $value . qq|</b><input type="hidden" name="$field" value="$value" $fieldproplist>|;
			$self->{FORM}->{"fields$step"}->{$field}->{help} = "";
			
			if (ref($self->{FORM}->{"fields$step"}->{$field}->{drawfunction}) eq "CODE") {
				$item = &$self->{FORM}->{"fields$step"}->{$field}->{drawfunction}($item);
			}
		}

		if ($item) {
			$newrow = $self->{FORM}->{"$fields$step"}->{$field}->{rowtemplate} || $rowtemplate;

			if ($self->{FORM}->{options}->{showerrors} != 0) {
				if ($errorlist->{$field} ne "") {
					$errors = $self->{FORM}->{templates}->{starterrorlist} . join($self->{FORM}->{templates}->{joinerrorlist}, map { $self->{FORM}->{templates}->{starterror} . $_ . $self->{FORM}->{templates}->{enderror} } @{$errorlist->{$field}}) . $self->{FORM}->{templates}->{enderrorlist};
				} else {
					$errors = "";
				}
			}

			if (!$errors) {
				$errors = $self->{FORM}->{templates}->{noerrors};
			}

			if ($self->{FORM}->{"fields$step"}->{$field}->{help} ne "") {
				$help .= $self->{FORM}->{templates}->{starthelp} . $self->um->replaceinto($self->{FORM}->{"fields$step"}->{$field}->{help}, { value => $value }) . $self->{FORM}->{templates}->{endhelp};
			} else {
				$help = "";
			}

			$newrow = $self->um->replaceinto($newrow, { label => $self->{FORM}->{templates}->{startlabel} . $label . $self->{FORM}->{templates}->{endlabel}, errors => $errors, help => $help, tip => "", required => ($self->{FORM}->{"fields$step"}->{$field}->{required} ? $self->{FORM}->{templates}->{required} : "") });
			$newrow = $self->um->replaceinto($newrow, { item => $self->{FORM}->{templates}->{startitem} . $item . $self->{FORM}->{templates}->{enditem} });
			
			$html .= $newrow;

			my $replacefield = $field;
			$replacefield =~ s/\-//g;
			$surround = $self->um->replaceinto($surround, { $replacefield => $self->um->replaceinto($fieldonlytemplate, { item => $self->{FORM}->{templates}->{startitem} . $item . $self->{FORM}->{templates}->{enditem}, errors => $errors, help => $help }) });
			
		}

	}

	# Output Footer
	$foottemplate = $self->um->replaceinto($foottemplate, { buttons => $buttons });
	$html .= $foottemplate;

	if ($surround) {
		return $self->um->replaceinto($surround, { buttons => $buttons, method => $method, action => $action, enctype => ($self->{FORM}->{options}->{enctype} eq "" ? "" : qq| enctype="| . $self->{FORM}->{options}->{enctype} . qq|"|), id => ($self->{FORM}->{options}->{formid} eq "" ? "" : qq| id="| . $self->{FORM}->{options}->{formid} . qq|"|), class => ($self->{FORM}->{options}->{formclass} eq "" ? "" : qq| class="| . $self->{FORM}->{options}->{formclass} . qq|"|), name => ($self->{FORM}->{options}->{formname} eq "" ? "" : qq| name="| . $self->{FORM}->{options}->{formname} . qq|"|) });
	} else {
		return $html;
	}

}

# Checks to see that the form passes all validation
sub validate {

	my $self				= shift;
	my $step				= shift;

	my (%errorlist, $validate, $result, $x, @fieldlist, $value, $addrspec, $field, $error, $regexp, $label);

	if ($self->{FORM}->{options}->{wizard} == 1 and $step eq "") {
		die "You must specify the wizard step to validate.";
	}

	if ($self->{FORM}->{options}->{wizard} == 1) {
		@fieldlist = @{$self->{FORM}->{options}->{"fieldlist"}->{$step}};
	} else {
		@fieldlist = @{$self->{FORM}->{options}->{"fieldlist"}};
	}

	foreach $field (@fieldlist) {
		$label = $self->{FORM}->{"fields$step"}->{$field}->{"label"} || $field;

		if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "date" and $self->{FORM}->{"fields$step"}->{$field}->{validdateadded} == 0) {
			push(@{$self->{FORM}->{"fields$step"}->{$field}->{validation}}, \&validdate);
			push(@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}}, "");
			$self->{FORM}->{"fields$step"}->{$field}->{validdateadded} = 1;

		} elsif (($self->{FORM}->{"fields$step"}->{$field}->{type} eq "select" or $self->{FORM}->{"fields$step"}->{$field}->{type} eq "radio" or $self->{FORM}->{"fields$step"}->{$field}->{type} eq "checkbox") and $self->{FORM}->{"fields$step"}->{$field}->{validoptionadded} == 0 and $self->{FORM}->{"fields$step"}->{$field}->{listvalueonly} == 1) {
			push(@{$self->{FORM}->{"fields$step"}->{$field}->{validation}}, \&validoption);
			push(@{$self->{FORM}->{"fields$step"}->{$field}->{validationerrors}}, "");
			$self->{FORM}->{"fields$step"}->{$field}->{validoptionadded} = 1;

		}


		$x = 0;
		foreach $validate (@{$self->{FORM}->{"fields$step"}->{$field}->{"validation"}}) {

			$error = $self->{FORM}->{"fields$step"}->{$field}->{validationerrors}->[$x] || $self->{FORM}->{defaulterror} || "You must enter a value for %LABEL%.";
			$error = $self->um->replaceinto($error, { "label" => $label });

			if ($validate ne "") {

				if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "date") {
					if ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 1) {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute"));
					} elsif ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 2) {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute")) . ":" . sprintf("%02d", $self->um->request->param("$field-second"));
					} else {
						$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day"));
					}
				} else {
					$value = $self->um->request->param($field);
				}
				
				if ($validate eq "_notblank") {
					if ($value eq "") {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_alldigits") {
					if ($value !~ /^\d+$/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_alpha") {
					if ($value !~ /[\p{Alphabetic}]/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_alphanum") {
					if ($value !~ /[\p{Alphabetic}0-9]/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_telephone") {
					if ($value =~ /[^0-9\-\+\s\(\)]/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_nospaces") {
					if ($value =~ /[\h\v]/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_nodigits") {
					if ($value =~ /\d/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_isodate") {
					if ($value !~ /\d\d\d\d-\d\d-\d\d/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_isodatetime") {
					if ($value !~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_isodatetimesec") {
					if ($value !~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/) {
						push(@{$errorlist{$field}}, $error);
					}

				} elsif ($validate eq "_postcode") {
        			if ($value !~ /^([A-PR-UWYZ0-9][A-HK-Y0-9][AEHMNPRTVXY0-9]?[ABEHMNPRVWXY0-9]? [0-9][ABD-HJLN-UW-Z]{2}|GIR 0AA)$/i) {
                		push(@{$errorlist{$field}}, $error);
        			}
        			
				} elsif (ref($validate) eq "CODE") {
					$result = &$validate($self, $field, $value);
					if (defined($result)) {
						push(@{$errorlist{$field}}, $result || $error);
					}
				} else {
					$regexp = qr/$validate/;
					if ($value !~ m/$regexp/) {
						push(@{$errorlist{$field}}, $error);
					}

				}
			}

			$x++;

		}

	}

	if (%errorlist) {
		return \%errorlist;
	} else {
		return undef;
	}

}

sub selectdate {

	my $self				= shift;
	my $startdate			= shift;
	my $prefix				= shift;
	my $includetime			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;

	my ($currenttimestamp, $selectedday, $selectedmonth, $selectedyear, $selectedhour, $selectedminute, $selectedsecond);

	if ($startdate =~ /:/ and $includetime == 1) {
		($selectedyear, $selectedmonth, $selectedday, $selectedhour, $selectedminute, $selectedsecond) = $startdate =~ /(\d{0,4})\-(\d{0,2})\-(\d{0,2})\s(\d{0,2}):(\d{0,2})/;
	} elsif ($startdate =~ /:/ and $includetime == 2) {
		($selectedyear, $selectedmonth, $selectedday, $selectedhour, $selectedminute, $selectedsecond) = $startdate =~ /(\d{0,4})\-(\d{0,2})\-(\d{0,2})\s(\d{0,2}):(\d{0,2}):(\d{0,2})/;
	} else {
		($selectedyear, $selectedmonth, $selectedday) = split(/-/, $startdate);
	}

	if ($includetime == 1) {
		return $self->selectday("$prefix-day", int($selectedday), $withblank, $extraprops, $prefix) . " " . $self->selectmonth("$prefix-month", int($selectedmonth), $withblank, $extraprops, $prefix) . " " . $self->selectyear("$prefix-year", $selectedyear, $withblank, $extraprops, $prefix) . " &nbsp; " . $self->selecthour("$prefix-hour", $selectedhour, $withblank, $extraprops, $prefix) . ":" . $self->selectminute("$prefix-minute", $selectedminute, $withblank, $extraprops, $prefix);
	} elsif ($includetime == 2) {
		return $self->selectday("$prefix-day", int($selectedday), $withblank, $extraprops, $prefix) . " " . $self->selectmonth("$prefix-month", int($selectedmonth), $withblank, $extraprops, $prefix) . " " . $self->selectyear("$prefix-year", $selectedyear, $withblank, $extraprops, $prefix) . " &nbsp; " . $self->selecthour("$prefix-hour", $selectedhour, $withblank, $extraprops, $prefix) . ":" . $self->selectminute("$prefix-minute", $selectedminute, $withblank, $extraprops, $prefix) . ":" . $self->selectsecond("$prefix-second", $selectedsecond, $withblank, $extraprops, $prefix);
	} else {
		return $self->selectday("$prefix-day", int($selectedday), $withblank, $extraprops, $prefix) . " " . $self->selectmonth("$prefix-month", int($selectedmonth), $withblank, $extraprops, $prefix) . " " . $self->selectyear("$prefix-year", $selectedyear, $withblank, $extraprops, $prefix);
	}

}

sub selectday {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	return $self->select($name, $self->daylist($field), $selected, $withblank, $extraprops);

}

sub selectmonth {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	$extraprops = qq| class="span2"|;
	
	return $self->select($name, $self->monthlist($field), $selected, $withblank, $extraprops);

}

sub selectyear {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	return $self->select($name, $self->yearlist($field), $selected, $withblank, $extraprops, 1);

}

sub selecthour {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	return $self->select($name, $self->hourlist($field), $selected, $withblank, $extraprops);

}

sub selectminute {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	return $self->select($name, $self->minutelist($field), $selected, $withblank, $extraprops);

}

sub selectsecond {

	my $self				= shift;
	my $name				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $field				= shift;

	return $self->select($name, $self->secondlist($field), $selected, $withblank, $extraprops);

}

sub select {

	my $self				= shift;
	my $name				= shift;
	my $values				= shift;
	my $selected			= shift;
	my $withblank			= shift;
	my $extraprops			= shift;
	my $reverse				= shift;

	my ($item, $out);

	if (ref($values) eq "ARRAY") {
		$values = { map { $_ => $_ } @{$values} };
	}

	if ($reverse) {
		foreach $item (sort { $b <=> $a } (keys(%{$values}))) {
			if ($selected ne "" and $item eq $selected) {
				$out .= qq|<option value="$item" selected>| . $values->{$item} . qq|</option>|;
			} else {
				$out .= qq|<option value="$item">| . $values->{$item} . qq|</option>|;
			}
		}
		
	} else {
		foreach $item (sort { $a <=> $b } (keys(%{$values}))) {
			if ($selected ne "" and $item eq $selected) {
				$out .= qq|<option value="$item" selected>| . $values->{$item} . qq|</option>|;
			} else {
				$out .= qq|<option value="$item">| . $values->{$item} . qq|</option>|;
			}
		}
		
	}

	if ($withblank == 1) {
		return qq|<select name="$name" $extraprops><option value=""></option>| . $out . qq|</select>|;
	} else {
		return qq|<select name="$name" $extraprops>| . $out . qq|</select>|;
	}

}

sub submitted {

	my $self				= shift;
	my $values				= shift;
	my $step				= shift;
	my $multiplesep			= shift;

	my (%returndata, $field, $value, @sep);

	if (!defined $multiplesep) {
		$multiplesep = ",";
	}

	if (ref($values) ne "ARRAY") {
		die "You must specify the fields you wish the submitted values for.";
	}

	foreach $field (@{$values}) {

		my $maxlength = $self->maxlength($field);

		if ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "date") {
			if ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 1) {
				$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute"));
			} elsif ($self->{FORM}->{"fields$step"}->{$field}->{includetime} == 2) {
				$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day")) . " " . sprintf("%02d", $self->um->request->param("$field-hour")) . ":" . sprintf("%02d", $self->um->request->param("$field-minute")) . ":" . sprintf("%02d", $self->um->request->param("$field-second"));
			} else {
				$value = $self->um->request->param("$field-year") . "-" . sprintf("%02d", $self->um->request->param("$field-month")) . "-" . sprintf("%02d", $self->um->request->param("$field-day"));
			}
			
		} elsif ($self->{FORM}->{"fields$step"}->{$field}->{type} eq "checkbox") {
			$value = [ $self->um->request->param($field) ];
			
		} else {
			$value = $self->um->request->param($field);
		}
		
		if (ref($value) ne "ARRAY" and $maxlength) {
			$value = substr($value, 0, $maxlength);
		}

		$returndata{$field} = $value;

	}

	return \%returndata;

}

sub defaulttemplates {

	my $self				= shift;

	$self->template("head", $self->um->getblock("form/header"));
	$self->template("row", $self->um->getblock("form/row"));
	$self->template("foot", $self->um->getblock("form/footer"));
	$self->template("starthelp",  $self->um->getblock("form/helpstart"));
	$self->template("endhelp",  $self->um->getblock("form/helpend"));
	$self->template("seperator",  $self->um->getblock("form/seperator"));
	$self->template("sectionhead",  $self->um->getblock("form/sectionhead"));
	$self->template("required",  $self->um->getblock("form/required"));
	$self->template("starterrorlist",  $self->um->getblock("form/errorstartlist"));
	$self->template("joinerrorlist",  $self->um->getblock("form/errorjoinlist"));
	$self->template("starterror",  $self->um->getblock("form/errorstart"));
	$self->template("enderror",  $self->um->getblock("form/errorend"));
	$self->template("fieldonly",  $self->um->getblock("form/fieldonly"));
	
	return;
}

sub validdate {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;

	my ($result);

	if (!$value or $value =~ "-00-00") {
		return undef;
	}

	my $submitted = $self->submitted([ $field ]);
	
	if ($submitted->{$field} eq "-00-00" and $self->{FORM}->{"fields"}->{$field}->{showblank} == 1) {
		return undef;
	}
	
	# Pass through a date function
	eval {
		$result = $self->um->date->parsedate($submitted->{$field});
	};
	if ($@ or !defined $result) {
		return "You must enter a valid date.";
	} else {
		return undef;
	}

}

sub validoption {

	my $self				= shift;
	my $field				= shift;
	my $value				= shift;

	my ($inlist, $option, $optionvalue);

	# BUG: Wouldn't actually work if you were doing a wizard step
	# BUG: Probably doesn't work well for multiple checkboxes or multiple selection dropdowns either

	$inlist = 0;
	foreach $option (@{$self->{FORM}->{"fields"}->{$field}->{options}}) {
		($optionvalue) = keys(%{$option});
		if ($value eq $optionvalue) {
			$inlist = 1;
			last;
		}
	}
	if ($inlist == 0) {
		return "Please choose from the available options.";
	} else {
		return undef;
	}

	return undef;

}

1;
