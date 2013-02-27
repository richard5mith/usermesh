
package Usermesh::Helpers::Html;

use strict;

use Text::Markdown();
use HTML::Entities qw(encode_entities decode_entities);
use Data::Dumper;

sub new {

	my $proto				= shift;
	my $class				= ref($proto) || $proto;
	
	my $self				= bless {}, $class;
	
	$self->{UM}				= shift;
	
	my $data				= shift;

	$self->{MARKDOWN}		= Text::Markdown->new();

	# Columns
	$self->{HTML}->{columns}->{templates}->{head} = q|<table cellspacing="0" cellpadding="0" width="100%">|;
	$self->{HTML}->{columns}->{templates}->{row} = q|<tr>%COLUMNS%</tr>|;
	$self->{HTML}->{columns}->{templates}->{column} = q|<td>%VALUE%</td>|;
	$self->{HTML}->{columns}->{templates}->{foot} = q|</table>|;

	# Tabulate
	$self->{HTML}->{tabulate}->{templates}->{head} = q|<div id="%LISTNAME%"><table class="table table-striped">|;
	$self->{HTML}->{tabulate}->{templates}->{row} = q|<tr>%COLUMNS%</tr>|;
	$self->{HTML}->{tabulate}->{templates}->{column} = q|<td>%VALUE%</td>|;
	$self->{HTML}->{tabulate}->{templates}->{titlerow} = q|<thead><tr>%COLUMNS%</tr></thead>|;
	$self->{HTML}->{tabulate}->{templates}->{titlecolumn} = q|<th>%VALUE%</th>|;
	$self->{HTML}->{tabulate}->{templates}->{foot} = q|</table></div>|;
	
	if (defined $data) {
		if (ref($data) eq "ARRAY") { 
			$self->{HTML}->{data} = $data;
		} else {
			die "Data must be an array of values (for columns) or an array of arrays (for tabulate).";
		}
	}
	
	return $self;
}

sub um {

	my $self = shift;	
	
	return $self->{UM};
	
}

sub data {

	my $self				= shift;
	my $data				= shift;

	if (ref($data) eq "ARRAY" or !defined $data) { 
		$self->{HTML}->{data} = $data;
	} else {
		die "Data must be an array of values or an array of key arrays.";
	}

	return 1;

}

sub template {

	my $self				= shift;
	my $type				= shift;
	my $template			= shift;
	my $value				= shift;
	my $column				= shift;
	my $row					= shift;

	if ((defined $row or defined $column) and $type eq "tabulate") {
		if (!defined $value) {
			return $self->{HTML}->{$type}->{templates}->{"$template-$column-$row"};
		} else {
			$self->{HTML}->{$type}->{templates}->{"$template-$column-$row"} = $value;
			return 1;
		}
	} else {
		if (!defined $value) {
			return $self->{HTML}->{$type}->{templates}->{"$template"};
		} else {
			$self->{HTML}->{$type}->{templates}->{"$template"} = $value;
			return 1;
		}
	}
}

sub columns {

	my $self				= shift;
	my $columns				= shift;

	my ($out, $item, $x, $columndata, $columnticker, $rowticker);

	if ($#{$self->{HTML}->{data}} != -1) {
		$out .= $self->{HTML}->{columns}->{templates}->{head};
	}

	$x = 1;
	$columndata = "";
	$columnticker = 0;
	$rowticker = 0;
	foreach $item (@{$self->{HTML}->{data}}) {

		if (ref($self->{HTML}->{columns}->{templates}->{column}) eq "ARRAY") {
			$columndata .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{column}->[$columnticker], { value => $item });
			$columnticker++;
			if ($columnticker > $#{$self->{HTML}->{columns}->{templates}->{column}}) {
				$columnticker = 0;
			}
		} else {
			$columndata .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{column}, { value => $item });
		}

		if ($x % $columns == 0) {
			if (ref($self->{HTML}->{columns}->{templates}->{row}) eq "ARRAY") {
				$out .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{row}->[$rowticker], { columns => $columndata });
				$rowticker++;
				if ($rowticker > $#{$self->{HTML}->{columns}->{templates}->{row}}) {
					$rowticker = 0;
				}
			} else {
				$out .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{row}, { columns => $columndata });
			}

			$columndata = "";
		}
		$x++;
	}

	# If there's any remaining column data
	if ($columndata) {
		if (ref($self->{HTML}->{columns}->{templates}->{row}) eq "ARRAY") {
			$out .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{row}->[$rowticker], { columns => $columndata });
			$rowticker++;
			if ($rowticker > $#{$self->{HTML}->{columns}->{templates}->{row}}) {
				$rowticker = 0;
			}
		} else {
			$out .= $self->um->replaceinto($self->{HTML}->{columns}->{templates}->{row}, { columns => $columndata });
		}
	}

	if ($#{$self->{HTML}->{data}} != -1) {
		$out .= $self->{HTML}->{columns}->{templates}->{foot};
	}

	return $out;

}

sub tabulate {

	my $self				= shift;

	my ($out, $x, $columns, $rowtemp, $coltemp, $y, $columnticker, $rowticker, $colour, $nextcolour, $nextwidth, $width, $newrow, $newcolumn, $titlename);
	my ($row, $col, $listname);

	my $listname = $self->{HTML}->{tabulate}->{listname};

	$out .= $self->um->replaceinto($self->{HTML}->{tabulate}->{templates}->{head}, { listname => $listname });

	$nextcolour = 0;
	$rowticker = 0;
	$y = 0;
	foreach $row (@{$self->{HTML}->{data}}) {

		# Go through each column of data and build up the variable $columns with all the data
		$x = 0;
		$columns = "";
		$columnticker = 0;
		$nextwidth = 0;
		foreach $col (@{$row}) {

			if ($y == 0 and $self->{HTML}->{tabulate}->{titlerow} == 1) {
				$titlename = "title";
#				$coltemp = "titlecolumn";
#				$rowtemp = "titlerow";
			} else {
				$titlename = "";
			}

			# Check to see if there's a specific HTML template for this row
			if (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}row-$x-$y"}) {		
				$rowtemp = "${titlename}row-$x-$y";
			} elsif (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}row--$y"}) {
				$rowtemp = "${titlename}row--$y";
			} elsif (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}row-$x-"}) {
				$rowtemp = "${titlename}row-$x-";
			} else {
				$rowtemp = "${titlename}row";
			}

			# Check to see if there's a specific HTML template for this column
			if (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}column-$x-$y"}) {		
				$coltemp = "${titlename}column-$x-$y";
			} elsif (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}column-$x-"}) {
				$coltemp = "${titlename}column-$x-";
			} elsif (defined $self->{HTML}->{tabulate}->{templates}->{"${titlename}column--$y"}) {
				$coltemp = "${titlename}column--$y";
			} else {
				$coltemp = "${titlename}column";
			}

			# If the template for the column is an array, then cycle through them
			if (ref($self->{HTML}->{tabulate}->{templates}->{$coltemp}) eq "ARRAY") {
				$newcolumn = $self->um->replaceinto($self->{HTML}->{tabulate}->{templates}->{$coltemp}->[$columnticker], { value => $col });
				if (ref($self->{HTML}->{tabulate}->{widths}) eq "ARRAY") {
					$width = $self->{HTML}->{tabulate}->{widths}->[$nextwidth];
					if ($width) {
						$newcolumn =~ s/<td/<td width="$width"/i;
					}
					$nextwidth++;
					if ($nextwidth > $#{$self->{HTML}->{tabulate}->{widths}}) {
						$nextwidth = 0;
					}
				}
				$columns .= $newcolumn;
				$columnticker++;
				if ($columnticker > $#{$self->{HTML}->{tabulate}->{templates}->{$coltemp}}) {
					$columnticker = 0;
				}
			} else {
				$newcolumn = $self->um->replaceinto($self->{HTML}->{tabulate}->{templates}->{$coltemp}, { value => $col });
				if (ref($self->{HTML}->{tabulate}->{widths}) eq "ARRAY") {
					$width = $self->{HTML}->{tabulate}->{widths}->[$nextwidth];
					if ($width) {
						$newcolumn =~ s/<td/<td width="$width"/i;
					}
					$nextwidth++;
					if ($nextwidth > $#{$self->{HTML}->{tabulate}->{widths}}) {
						$nextwidth = 0;
					}
				}
				$columns .= $newcolumn;
			}
			
			$x++;
		}
		# If the template for the row is an array, then cycle through them, then replace the value of $columns we just built up into the row
		if (ref($self->{HTML}->{tabulate}->{templates}->{$rowtemp}) eq "ARRAY") {
			$newrow = $self->um->replaceinto($self->{HTML}->{tabulate}->{templates}->{$rowtemp}->[$rowticker], { columns => $columns });
			if (ref($self->{HTML}->{tabulate}->{rowcolour}) eq "ARRAY") {
				$colour = $self->{HTML}->{tabulate}->{rowcolour}->[$nextcolour];
				if ($colour) {
					$newrow =~ s/<tr/<tr bgcolor="$colour"/i;
				}
				$nextcolour++;
				if ($nextcolour > $#{$self->{HTML}->{tabulate}->{rowcolour}}) {
					$nextcolour = 0;
				}
			}
			$out .= $newrow;
			$rowticker++;
			if ($rowticker > $#{$self->{HTML}->{tabulate}->{templates}->{$rowtemp}}) {
				$rowticker = 0;
			}
		} else {
			$newrow = $self->um->replaceinto($self->{HTML}->{tabulate}->{templates}->{$rowtemp}, { columns => $columns });
			if (ref($self->{HTML}->{tabulate}->{rowcolour}) eq "ARRAY") {
				$colour = $self->{HTML}->{tabulate}->{rowcolour}->[$nextcolour];
				if ($colour) {
					$newrow =~ s/<tr/<tr bgcolor="$colour"/i;
				}
				$nextcolour++;
				if ($nextcolour > $#{$self->{HTML}->{tabulate}->{rowcolour}}) {
					$nextcolour = 0;
				}
			}
			$out .= $newrow;
		}

		$y++;
	}
	$out .= $self->{HTML}->{tabulate}->{templates}->{foot};

	return $out;

}

sub listname {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{HTML}->{tabulate}->{listname};
	} else {
		$self->{HTML}->{tabulate}->{listname} = $value;
		return 1;
	}

}

# Set an array to be used for column widths
sub width {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{HTML}->{tabulate}->{widths};
	} else {
		$self->{HTML}->{tabulate}->{widths} = $value;
		return 1;
	}

}

# Set whether or not the first row should be converted to a title row
sub titlerow {

	my $self				= shift;
	my $value				= shift;

	if (!defined $value) {
		return $self->{HTML}->{tabulate}->{titlerow};
	} else {
		$self->{HTML}->{tabulate}->{titlerow} = $value;
		return 1;
	}

}

# Sets an array of colours to alternate between for each row
sub rowcolour {

	my $self				= shift;
	my $value				= shift;

	if (@_) {
		die "Too many arguments for rowcolour.";
	}

	if (!defined $value) {
		return $self->{HTML}->{tabulate}->{rowcolour};
	} else {
		if (ref($value) eq "ARRAY") {
			$self->{HTML}->{tabulate}->{rowcolour} = $value;
			return 1;
		} else {
			die "rowcolour must be an array of possible values to cycle through.";
		}
	}

}

sub simplelist {

	my $self				= shift;
	my $data				= shift;
	my $widths				= shift;
	my $align				= shift;
	my $start				= shift || 0;
	my $perpage				= shift;
	my $totalitems			= shift;
	my $listname			= shift || "list";
	my $notitle				= shift;

	my ($total, @rows, $row, $col, $id, $x, $out, $title, $page, $pagenumbers);

	if (!$notitle) {
		$title = shift(@{$data});
	}
	if (defined($totalitems)) {
		$total = $self->countpages($totalitems, $perpage);
		@rows = splice(@{$data}, 0, $perpage);
	} else {
		$total = $self->countpages($#{$data} + 1, $perpage);
		@rows = splice(@{$data}, $start, $perpage);
	}
	if (!$notitle) {
		unshift(@rows, $title);
	}

	$x = 0;
	foreach $row (@rows) {
		$id = $row->[0];
		shift(@{$row});
		$self->template("tabulate", "row--$x", qq|<tr id="r$listname$id">%COLUMNS%</tr>|);
		$x++;
	}

	if ($start > 0) {
		$page = ($start / $perpage) + 1;
	} else {
		$page = 1;
	}

	$self->data(\@rows);
	if (!$notitle) {
		$self->titlerow(1);
	}
	$self->width($widths);
	$self->listname($listname);

	if ($align) {
		$x = 0;
		foreach $col (@{$align}) {
			if ($col eq "l") {
				$self->template("tabulate", "titlecolumn-$x-", q|<th align="left">%VALUE%</td>|);
				$self->template("tabulate", "column-$x-", q|<td align="left">%VALUE%</td>|);
			} elsif ($col eq "r") {
				$self->template("tabulate", "titlecolumn-$x-", q|<th align="right">%VALUE%</td>|);
				$self->template("tabulate", "column-$x-", q|<td align="right">%VALUE%</td>|);
			} elsif ($col eq "c") {
				$self->template("tabulate", "titlecolumn-$x-", q|<th align="center">%VALUE%</td>|);
				$self->template("tabulate", "column-$x-", q|<td align="center">%VALUE%</td>|);
			} else {
				$self->template("tabulate", "titlecolumn-$x-", q|<th>%VALUE%</td>|);
				$self->template("tabulate", "column-$x-", q|<td>%VALUE%</td>|);
			}
			$x++;
		}
	}

	$out = $self->tabulate();
	$pagenumbers = $self->pagenumbers($total, $start, $perpage, 7, defined($totalitems) ? $totalitems : $#{$data} + 1);

	return ($out, $pagenumbers);

}

# sql				=> String containing the query to run, totally optional, you probably want to pass it fields, table, where and orderby instead
# sqlfields			=> Reference to an array containing the fields to replace into the sql placeholders
# fields			=> Reference to a list of all the fields from the database you want
# table				=> String containing the name of the database table to take them from
# where				=> An optional extra where clause, this is a good place to stick joins, the search field will be inserted after this
# orderby			=> An optional order by string
# perpage			=> Items per page
# searchform		=> Bool to specify if you want a search form, defaults to 0
# searchfields		=> A reference to an array containing a list of the fields in the database to compare the search field against
# searchlike		=> Should it search the fields listed in searchbox with a like
# searchhelp		=> A string containing the help text to display on the search form
# columnorder		=> A reference to a list of all the columns to show and in which order
# columndata		=> A reference to a hash where the key is the column name and the value is the data to put in that column. %TAGS% are replaced with the result from the db query
# columnformat		=> A reference to a hash where the key is the column name and the value is a reference to a sub to pass the value of this column to 
# labels			=> A reference to a hash where the key is the column name and the value is the column header OR a reference to an array containing an ordered list of labels
# widths			=> A reference to a hash where the key is the column name and the value is the HTML width of the column OR a reference to an array containing an ordered list of widths
# align				=> A reference to a hash where the key is the column name and the value is the align position of the column, l, c or r (left, centre, right) OR a reference to an array containing an ordered list of alignments
# checkbox			=> Bool to decide if you want checkboxes, defaults to 1
# checkall			=> Bool to decide if you want the check all checkbox, defaults to 1
# buttonaction		=> String containing the name of the action the button should go to
# buttontext		=> String containing the text for the button, default to "Delete",
# hiddenfields		=> HTML for extra hidden fields to be passed in the form
# unique			=> String containing the name of the column that's unique, default to "id"
# topbuttons		=> A reference to a list of hashes, where the key for each one is the button text and the value is the HTML link
# checkwidth		=> A string containing the HTML width for the checkbox column, defaults to 5% or 2% if no checkboxs
# button2			=> HTML for a 2nd submit button

sub simplerlist {

	my $self				= shift;
	my $params				= shift;

	my ($start, @cursor, $returned, @list, $unique, $x, @cursor2, $returned2, $total, $listcontent, $pagenumbers, $content, $form, $search, $field, @morewhere);
	my (@params, $param, $hiddenfields, $item, $data, $end, $buttons, $datastart);

	$start = $self->um->request->param("start") || 0;
	$search = $self->um->request->param("search");

	if (!defined($params->{checkbox})) {
		$params->{checkbox} = 1;
	}
	if (!defined($params->{checkall})) {
		$params->{checkall} = 1;
	}
	if (!defined($params->{buttontext})) {
		$params->{buttontext} = "Delete";
	}
	if (!defined($params->{unique})) {
		$params->{unique} = "id";
	}
	if (!defined($params->{checkwidth})) {
		$params->{checkwidth} = ($params->{checkbox} ? "5%" : "2%");
	}
	if (!defined($params->{listname})) {
		$params->{listname} = "list";
	}
	if (defined($params->{button2})) {
		$buttons = 2;
	} else {
		$buttons = 1;
	}

	if ($params->{orderby}) {
		$params->{orderby} = "order by $params->{orderby}";
	}

	$hiddenfields = "";
	@params = $self->um->request->param;

	if ($params->{searchform}) {
		$form = $self->um->form->create([ qw(search submit) ]);
		$form->defaulttemplates;
		$form->method("GET");
		$form->properties("search", { label => "Search", size => 40, help => $params->{searchhelp} || "Enter the text you want to search for." });
		$form->properties("submit", { type => "submit", label => "Search", class => "formbutton" });

		foreach $param (@params) {
			if ($param ne "search" and $param ne "submit" and $param ne "start") {
				$form->addfield($param);
				$form->properties($param, { type => "hidden", value => scalar($self->{CGI}->param($param)), forcevalue => 1 });
			}
		}

		$content .= $form->content();
		$content .= "<br>";
	
		if ($search) {
			foreach $field (@{$params->{searchfields}}) {
				push(@morewhere, "$field " . ($params->{searchlike} ? "like" : "=") . " " . $self->um->sql->quote( ($params->{searchlike} ? "%" : "") . $search . ($params->{searchlike} ? "%" : "") ));
			}
			if (@morewhere) {
				$params->{where} .= ($params->{where} ? " and " : "") . "(" . join(" or ", @morewhere) . ")";
			}
		}

	}

	if ($params->{where}) {
		$params->{whereand} = "and $params->{where}";
		$params->{where} = "where $params->{where}";
	}

	if ($params->{topbuttons}) {
		$content .= $self->buttons(@{$params->{topbuttons}}) . "<br>";
	}

	@list = ();
	if (ref($params->{data}) eq "ARRAY") {
		$data = $params->{data};
		$total = $params->{totalrows} || $#{$params->{data}} + 1;

		if ($params->{totalrows}) {
			$datastart = 0;  
		} else {
			$datastart = $start;
		}
		
		if ($params->{perpage} and !$params->{totalrows}) {
			$end = ($start+($params->{perpage}-1));
		} else {
			$end = ($start+($total-1));
		}
		
		if ($end > $#{$data}) {
			$end = $#{$data};
		}
		
		@{$data} = @{$data}[$datastart..$end];

	} else {
		if ($params->{sql}) {
			$params->{sql} =~ s/%WHERE%/$params->{where}/;
			$params->{sql} =~ s/%WHEREAND%/$params->{whereand}/;

			@cursor = $self->um->sql->query($params->{sql} . ($params->{nopagenumbers} ? "" : " limit $start," . $params->{perpage}), @{$params->{sqlfields}});
		} else {
			@cursor = $self->um->sql->query("select SQL_CALC_FOUND_ROWS " . join(", ", @{$params->{fields}}) . " from " . $params->{table} . " $params->{where} $params->{orderby}" . ($params->{nopagenumbers} ? "" : " limit $start," . $params->{perpage}));
		}
		@cursor2 = $self->um->sql->query("select found_rows()");
		if ($returned2 = $cursor2[0]->fetchrow_hashref) {
			$total = $returned2->{"found_rows()"};
		}

		$data = $cursor[0]->fetchall_arrayref({});
	}

	# Stick a totals row to the foot of the results
	if (ref($params->{totalsrow}) eq "ARRAY") {
		push @{$data}, $params->{totalsrow};
	}

	foreach $returned (@{$data}) {
		$unique = $returned->{$params->{unique}};
		
		$x = 0;
		push(@list, [
						$unique,
						($params->{checkbox} && !$returned->{nocheckbox} ?
							qq|<input type="checkbox" name="$params->{listname}item" id="c$params->{listname}$unique" value="$unique" onclick="hrow('$params->{listname}$unique',$buttons,'$params->{listname}');">|
						:
							"&nbsp;"
						),
						map {
							if ($params->{columndata}->{$_} ne "") {
								if ($params->{columnformat}->{$_}) {
									$item = &{$params->{columnformat}->{$_}}($self->um->replaceinto($params->{columndata}->{$_}, { %{$returned}, start => $start, search => $search }), $returned);
									if ($item eq "") {
										"&nbsp;"
									} else {
										$item;
									}
								} else {
									$item = $self->um->replaceinto($params->{columndata}->{$_}, { %{$returned}, start => $start, search => $search });
									if ($item eq "") {
										"&nbsp;"
									} else {
										$item;
									}
								}
							} else {
								if ($params->{columnformat}->{$_}) {
									$item = &{$params->{columnformat}->{$_}}($returned->{$_}, $returned);
									if ($item eq "") {
										"&nbsp;"
									} else {
										$item;
									}
								} else {
									if ($returned->{$_} ne "") {
										$returned->{$_}
									} else {
										"&nbsp;"
									}
								}
							}
						}
						@{$params->{columnorder}}
					
					]);
	}

	if (@list) {
		if (!$params->{nolabelrow}) {
			unshift(@list, [ "", ($params->{checkall} ? qq|<input type="checkbox" name="check" onclick="checkall('$params->{listname}item',this.checked);">| : ""), (ref($params->{labels}) eq "ARRAY" ? @{$params->{labels}} : map { $params->{labels}->{$_} || ucfirst($_) } @{$params->{columnorder}}) ]);
		}
		($listcontent, $pagenumbers) = $self->simplelist(\@list, (ref($params->{widths}) eq "ARRAY" ? [ ($params->{checkbox} ? "10%" : "2%"), @{$params->{widths}} ] : [ $params->{checkwidth}, map { $params->{widths}->{$_} } @{$params->{columnorder}} ]), (ref($params->{align}) eq "ARRAY" ? [ "c", @{$params->{align}} ] : [ "c", map { $params->{align}->{$_} } @{$params->{columnorder}} ]), $start, ($params->{nopagenumbers} ? $total : ($params->{perpage} || $total)), $total, $params->{listname}, $params->{nolabelrow});

		if ($params->{nopagenumbers}) {
			$pagenumbers = "";
		}

		if ($params->{checkbox}) {
			$content .= qq|<form method="POST" action="$params->{buttonaction}" style="margin-top:0">$listcontent<p><input type="submit" class="btn" name="do" value="$params->{buttontext}" id="$params->{listname}delete" disabled>&nbsp;$params->{button2}</p>$pagenumbers$params->{hiddenfields}</form><p>&nbsp;</p>|;
		} elsif ($params->{justform}) {
			$content .= qq|<form method="POST" action="$params->{buttonaction}" style="margin-top:0">$listcontent<p><input type="submit" class="btn" name="do" value="$params->{buttontext}" id="$params->{listname}delete">&nbsp;$params->{button2}</p>$params->{hiddenfields}</form><p>&nbsp;</p>|;
		} else {
			$content .= qq|$listcontent<p>&nbsp;</p>$pagenumbers<p>&nbsp;</p>|;
		}

	} else {
		$content .= ($params->{nonefound} || qq|<p>No entries were found to display.</p>|);
	}

	return $content;

}

sub pagenumbers {

	my $self				= shift;
	my $pages				= shift;
	my $start				= shift;
	my $perpage				= shift;
	my $thumbsperpage		= shift;
	my $totalitems			= shift;
	my $url					= shift;
	my $niceurls			= shift;
	my $pagevalues			= shift;
	my $infoline			= shift;
	my $actualpage			= shift;
	
	my ($difference, $nextpage, $nextpagevalue, $page, @pagenumbers);
	my ($prevpage, $prevpagevalue, $star, $startpage, $stoppage, $x, $currenturl, $startitem, $enditem);
	my ($lastpage, $pagenumbers, $firstpage);
	
	if ($url ne "") {
		$currenturl = $url;
	} else {
		$currenturl = $self->um->request->req->url->to_string;
		
		if ($niceurls) {
			$currenturl =~ s!/page/(\d+)!!g;
			
		} else {
			$currenturl =~ s/(?:&|;|\?)start=(.*?)(&|;|$)/$2/g;
			
		}
	}
	if ($currenturl =~ /\?/) {
		$currenturl .= "&";
	} else {
		$currenturl .= "?";
	}

	if ($#{$pagevalues} != -1) {
		$x = 1;
		foreach my $item (@{$pagevalues}) {
			if ($item eq $actualpage) {
				$page = $x;
				last;
			}
			$x++;
		}
	} else {
		if ($start > 0) {
			$page = int($start / $perpage) + 1;
		} else {
			$page = 1;
		}
	}
	
	# Create the previous page link
	$prevpagevalue = $start - $perpage;
	if ($prevpagevalue < 0) {
		$prevpage = qq|<li class="disabled"><a href="#" onclick="return false;">&larr;</a></li>|;
	} else {
		if ($niceurls) {
			$prevpagevalue = $self->offsettopage($prevpagevalue, $perpage);
		}
		if ($#{$pagevalues} != -1) {
			$prevpagevalue = $pagevalues->[$start-$perpage];
		}
		$prevpage = qq|<li><a href="${currenturl}start=$prevpagevalue">&larr;</a></li>|;
	}

	if ($pages > $thumbsperpage) {
		if ($page > ($thumbsperpage / 2)) {
			$startpage = $page - int($thumbsperpage / 2);
			$stoppage = $page + int($thumbsperpage / 2);
		} else {
			$startpage = 1;
			$stoppage = $thumbsperpage;
		}
	} else {
		$startpage = 1;
		$stoppage = $thumbsperpage;
	}

	if ($stoppage > $pages) {
		$difference = $stoppage - $pages;
		$stoppage = $pages;
		$startpage = $startpage - $difference;
	}

	if ($startpage < 1) {
		$startpage = 1;
	}

	# Create the page numbers
	$pagenumbers = "";
	for ($x = $startpage; $x <= $stoppage; $x++) {
		if ($page == $x) {
			push(@pagenumbers, qq|<li class="active"><a href="#" onclick="return false;">$x</a></li>|);
		} else {
			$star = ($x - 1) * $perpage;
			if ($niceurls) {
				$star = $self->offsettopage($star, $perpage);
			}
			if ($#{$pagevalues} != -1) {
				$star = $pagevalues->[$x-1];
			}
			push(@pagenumbers, qq|<li><a href="${currenturl}start=$star">$x</a></li>|);
		}
	}
	
	# Always show the first page
	if ($startpage > 1) {
		if ($startpage != 2) {
			unshift(@pagenumbers, qq|<li class="disabled"><a href="#" onclick="return false;">...</a></li>|);
		}
		if ($niceurls) {
			$firstpage = 1;
		} else {
			$firstpage = 0;
		}
		if ($#{$pagevalues} != -1) {
			$firstpage = $pagevalues->[0];
		}
		unshift(@pagenumbers, qq|<li><a href="${currenturl}start=$firstpage">1</a></li>|);
	}

	# Always show the last page
	if ($stoppage < $pages) {
		$lastpage = ($pages - 1) * $perpage;
		if ($stoppage != $pages - 1) {
			push(@pagenumbers, qq|<li class="disabled"><a href="#" onclick="return false;">...</a></li>|);
		}
		if ($niceurls) {
			$lastpage = $self->offsettopage($lastpage, $perpage);
		}
		if ($#{$pagevalues} != -1) {
			$lastpage = $pagevalues->[$#{$pagevalues}];
		}		
		push(@pagenumbers, qq|<li><a href="${currenturl}start=$lastpage">$pages</a></li>|);
	}

	# Create the next page link
	$nextpagevalue = $start + $perpage;
	if ($nextpagevalue >= $pages * $perpage) {
		$nextpage = qq|<li class="disabled"><a href="#" onclick="return false;">&rarr;</a></li>|;
	} else {
		if ($niceurls) {
			$nextpagevalue = $self->offsettopage($nextpagevalue, $perpage);
		}
		if ($#{$pagevalues} != -1) {
			$nextpagevalue = $pagevalues->[$start+$perpage];
		}		
		$nextpage = qq|<li><a href="${currenturl}start=$nextpagevalue">&rarr;</a></li>|;
	}

	$startitem = $start + 1;
	$enditem = ($startitem + $perpage > $totalitems) ? $totalitems : ($startitem - 1) + $perpage;

	if ($niceurls) {
		$nextpage =~ s!(&|\?)start=(\d+)!/page/$2!;
		$nextpage =~ s!//!/!;
		$prevpage =~ s!(&|\?)start=(\d+)!/page/$2!;
		$prevpage =~ s!//!/!;
		foreach (@pagenumbers) {
			$_ =~ s!(&|\?)start=(\d+)!/page/$2!;
			$_ =~ s!//!/!;
		}
	} elsif ($#{$pagevalues} != -1) {
		$nextpage =~ s!href=".*?start=(.+)"!href="$1"!;
		$prevpage =~ s!href=".*?start=(.+)"!href="$1"!;

		foreach (@pagenumbers) {
			$_ =~ s!href=".*?start=(.+)"!href="$1"!;
		}		
	}

	return qq|<div class="pagination pagination-centered"><ul>$prevpage| . join("", @pagenumbers) . qq|$nextpage</ul></div>| . ($infoline ? qq|<p align="center">$totalitems items, showing $startitem to $enditem</p>| : "");

}

sub offsettopage {
	
	my $self				= shift;
	my $start				= shift;
	my $perpage				= shift;
	
	my $page;
	
	if ($start > 0) {
		$page = int($start / $perpage) + 1;
	} else {
		$page = 1;
	}
	
	return $page;
	
}

sub countpages {

	my $self				= shift;
	my $total				= shift;
	my $perpage				= shift;

	my ($pages);

	if (($total / $perpage) == int($total / $perpage)) {
		$pages = $total / $perpage;
	} else {
		$pages = int($total / $perpage) + 1;
	}

	return $pages;

}

sub buttons {
	
	my $self			= shift;
	my @buttons			= @_;

	my ($out);
	foreach my $button (@buttons) {
		my ($text) = keys(%{$button});
		if ($button->{$text}) {
			my $class = "";
			my @htmloptions = ();
			my $justtext;
			
			# Any options on the text side
			if ($text =~ /\|/) {
				my ($options);
				($justtext, $class, $options) = split(/\|/, $text, 3);

				if ($options) {
					my @parts = split(/\|/, $options);
					foreach my $part (@parts) {
						my ($name, $value) = split(/=/, $part, 2);
						push(@htmloptions, qq|$name="$value"|);
					}
				}
			}
			if ($class) {
				my $htmlops;
				if (@htmloptions) {
					$htmlops = " " . join(" ", @htmloptions);
				}
				$out .= qq|<a class="btn $class" href="$button->{$text}" $htmlops>$justtext</a> |;
			} else {
				$out .= qq|<a class="btn" href="$button->{$text}">$text</a> |;
			}
		} else {
			$out .= qq|<a class="btn" href="#" onclick="return false">$text</a> |;
		}
	}

	return qq|<div style="margin-bottom: 10px">$out</div>|;
	
}

sub breadcrumbs {

	my $self				= shift;
	my @items				= @_;

	my ($out, $text, $item);

	my $x = 0;
	foreach $item (@items) {
		$out .= qq|<li>|;
		($text) = keys(%{$item});
		if ($item->{$text}) {
			$out .= qq|<a href="$item->{$text}">$text</a>|;
		} else {
			$out .= qq|$text|;
		}
		
		if ($x != $#items) {
			$out .= qq|<span class="divider">/</span>|;
		}
		$out .= qq|</li>|;
		$x++;
	}

	return qq|<ul class="breadcrumb">$out</ul>|;
}

sub paragraphs {

	my $self				= shift;
	my @array				= @_;

	my ($detail, $first, $item);

	foreach $item (@array) {
		$detail .= qq|<p>$item</p>|;
	}

	return $detail;

}

sub hparagraphs {

	my $self				= shift;
	my @array				= @_;

	my ($detail, $first, $item);

	$first = 1;
	foreach $item (@array) {
		if ($first == 1) {
			$detail .= qq|<h1>$item</h1>|;

			$first = 2;
		} else {
			$detail .= qq|<p>$item</p>|;

		}
	}

	return $detail;

}

sub h2paragraphs {

	my $self				= shift;
	my @array				= @_;

	my $detail = $self->hparagraphs(@array);

	$detail =~ s/<h1/<h2/g;
	$detail =~ s/\/h1>/\/h2>/g;

	return $detail;
}

sub h3paragraphs {

	my $self				= shift;
	my @array				= @_;

	my $detail = $self->hparagraphs(@array);

	$detail =~ s/<h1/<h3/g;
	$detail =~ s/\/h1>/\/h3>/g;

	return $detail;
}

sub formathtml {

	my $self				= shift;
	my $p					= shift;

	my ($pre, $post, $imgtitle, $imgcaption);
	
	my $text = $p->{text};
	
	# TODO: make this an actual plugin system
	if ($p->{textplugins}) {
		$text =~ s!(?:[^\"\']|^)http(?:s|)://www.youtube.com/watch\?(?:.*?)v=(.*?)(?:&|;|$|\s).*?(\s|$)!<p><iframe width="640" height="360" src="http://www.youtube.com/embed/$1?rel=0" frameborder="0" allowfullscreen></iframe></p>!mg;
		$text =~ s!\[javascript\](.*?)\[/javascript\]!qq|<pre class="brush:js">| . $self->converthtml($1, { ">" => "&gt;", "<" => "&lt;" }) . qq|</pre>|!egms;
		$text =~ s!\[html\](.*?)\[/html\]!qq|<pre class="brush:html">| . $self->converthtml($1, { ">" => "&gt;", "<" => "&lt;" }) . qq|</pre>|!egms;
		$text =~ s!\[css\](.*?)\[/css\]!qq|<pre class="brush:css">| . $self->converthtml($1, { ">" => "&gt;", "<" => "&lt;" }) . qq|</pre>|!egms;
		$text =~ s!\[perl\](.*?)\[/perl\]!qq|<pre class="brush:perl">| . $self->converthtml($1, { ">" => "&gt;", "<" => "&lt;" }) . qq|</pre>|!egms;
		$text =~ s!\[shell\](.*?)\[/shell\]!qq|<pre class="brush:shell">| . $self->converthtml($1, { ">" => "&gt;", "<" => "&lt;" }) . qq|</pre>|!egms;
	}

	if ($p->{links}) {
		$text = $self->makeurls($text);
	}

	if ($p->{markdown}) {
		$text = $self->{MARKDOWN}->markdown($text);
	}

	return $text;

}

# Takes HTML and encodes it all so that it's displayed as plain text
sub striphtml {

	my $self				= shift;
	my $text				= shift;
	my $unsafe				= shift;
	
	$text = encode_entities($text, $unsafe);

	return $text;

}

# Takes HTML entities and converts them back to plain so that it can be displayed as HTML (or vice-versa)
sub converthtml {

	my $self				= shift;
	my $text				= shift;
	my $enty				= shift;
	
	if (ref($enty) eq "HASH") {
		foreach my $key (keys %{$enty}) {
			$text =~ s/\Q$key\E/$enty->{$key}/g;
		}

	} else {
		$text = decode_entities($text);
	}

	return $text;

}

sub makeurls {

	my $self				= shift;
	my $text				= shift;
	
	# URL
	$text =~ s/(^|[^"\w>])([\w]+:\/\/[\w\-?&\+:%#~,;=\.\/\@]+[\w\-&\+%#~=\/\@])($|[^"<])/$1<a href="$2">$2<\/a>$3/g;
	
	# Email
	$text =~ s/(^|\s)([a-z0-9_\-.]+\@[a-z0-9_\-.]+)(\W|\s|$)/$1<a href="mailto:$2">$2<\/a>$3/mig;
	
	return $text;

}

sub formatjs {
	
	my $self				= shift;
	my $p					= shift;
	
	$p->{text} =~ s/\'/\\'/g;
	$p->{text} =~ s/\n/\\n/g;
	
	return $p->{text};
	
}

1;
