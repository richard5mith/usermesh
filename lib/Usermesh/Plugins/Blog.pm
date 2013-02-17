
package Usermesh::Plugins::Blog;

use strict;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;
use YAML::XS qw(Load Dump LoadFile);

sub register {
	
	my ($self, $app) = @_;
	
	# This is where you register all the routes that this plugin will provide
	$app->routes->any('/admin/blog' => \&listposts);
	$app->routes->any('/admin/blog/add' => \&addeditpost);
	$app->routes->any('/admin/blog/edit/:postid' => \&addeditpost);
	$app->routes->post('/admin/blog/attach' => \&attachfile);
	$app->routes->post('/admin/blog/deletepost' => \&confirmdeleteposts);
#	$app->routes->any('/admin/blog/categories' => \&categories);

	# And this is where you can add to the sidebar menu
	$app->um->addtoadminmenu({ text => "Your Posts", link => "/admin/blog/", category => "Blog", top => 1, toptext => "Blog" });
	$app->um->addtoadminmenu({ text => "Add Blog Post", link => "/admin/blog/add/", category => "Blog" });
#	$app->um->addtoadminmenu({ text => "Categories", link => "/admin/blog/categories/", category => "Blog" });
	
	$app->helper(recentposts => \&recentposts);
	$app->helper(draftposts => \&draftposts);
	
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

sub recentposts {
	
	my $self = shift; # really it should be $app

	return shortpostlist($self, { state => "published" });
	
}

sub draftposts {
	
	my $self = shift; # really it should be $app, but well, you know...

	return shortpostlist($self, { state => "draft" });
	
}

sub foo {
    
    my $self = shift;
    
    print "helo";
    
}

sub shortpostlist {
	
	my $self = shift;
	my $filter = shift;
	
	my @data = getpostlist($self, $filter);
		
	my $output = $self->um->html->simplerlist({
		data			=> \@data,
		perpage			=> 10,
		nopagenumbers	=> 1,
		columnorder		=> [ qw(title niceurl type date state edit) ],
		columnformat	=> { 
			date => sub {
				return $self->um->date->formatdate($_[0], "D2/M2/Y1, h2:m2");
			},
			niceurl => sub {
				if ($_[1]->{state} eq "published") {
					return qq|<a href="$_[0]" target="_blank">$_[0]</a>|;
				} else {
					return $_[0];
				}
			},
			title => sub {
				if (not defined $_[0] or $_[0] eq "") {
					$_[1]->{body} =~ s!<script.*?>.*?</script>!!gms;
					$_[1]->{body} =~ s/<.*?>//gms;
					return substr($_[1]->{body}, 0, 40) . (length($_[1]->{body}) > 40 ? "..." : "");	
				} else {
					return $_[0];
				}
			}
		},
		columndata		=> { edit => qq|<a href="/admin/blog/edit/%ID%">Edit</a>| },
		labels			=> { niceurl => "URL", postdate => "Date", edit => "&nbsp;", title => "Title / Snippet" },
		widths			=> { title => "30%", date => "11%", niceurl => "30%", type => "10%", state => "8%", edit => "6%" },
		checkbox		=> 0,
		checkall		=> 0
	});
		
	return $output;	
	
}

# This action will render a template
sub listposts {
	
	my $self = shift;
	
	my ($output);
	
	$output .= $self->um->html->hparagraphs("Your Posts");
	$output .= $self->um->html->buttons({ "Add Blog Post|btn-primary" => "/admin/blog/add/" });
	
	my $form = $self->um->form(undef, [ "title", "type", "submit" ], $self->req->url, "GET");
	$form->p("title", { size => 40, class => "span6" });
	$form->p("type", { type => "select", options => [ { "" => "All" }, { "blog" => "Blog" }, { "twitter" => "Twitter" }, { "facebook" => "Facebook" }, { "foursquare" => "Foursquare" } ] });
	$form->p("submit", { type => "submit", label => "Search" });

	my $filters = {};	
	my $submit = $self->param("submit") || "";
	if ($submit ne "") {
		$filters = $form->submitted([ qw(title type) ]);
	}
	
	$output .= $self->um->html->h3paragraphs("Search Posts");
	$output .= $form->content() . "<br>";
	
	my @data = getpostlist($self, $filters);
		
	$output .= $self->um->html->simplerlist({
		data			=> \@data,
		perpage			=> 50,
		columnorder		=> [ qw(title niceurl type date state edit) ],
		columnformat	=> { 
			date => sub {
				return $self->um->date->formatdate($_[0], "D2/M2/Y1, h2:m2");
			},
			niceurl => sub {
				if ($_[1]->{state} eq "published") {
					return qq|<a href="$_[0]" target="_blank">$_[0]</a>|;
				} else {
					return $_[0];
				}
			},
			title => sub {
				if (defined $_[0] and $_[0] eq "") {
					$_[1]->{body} =~ s!<script.*?>.*?</script>!!gms;
					$_[1]->{body} =~ s/<.*?>//gms;
					return substr($_[1]->{body}, 0, 40) . (length($_[1]->{body}) > 40 ? "..." : "");	
				} else {
					return $_[0];
				}
			}
		},
		columndata		=> { edit => qq|<a href="/admin/blog/edit/%ID%">Edit</a>| },
		labels			=> { niceurl => "URL", postdate => "Date", edit => "&nbsp;", title => "Title / Snippet" },
		widths			=> { title => "30%", date => "11%", niceurl => "30%", type => "10%", state => "8%", edit => "6%" },
		buttonaction	=> "/admin/blog/deletepost",
	});
	
	return $self->render('admin/surround', replace => { title => "Your Posts", content => $output });

}

sub addeditpost {
	
	my $self = shift;
	
	my ($output);
	
	my $postid = $self->param("postid");

	if ($postid) {
		$output .= $self->um->html->hparagraphs("Edit Blog Post");		
	} else {
		$output .= $self->um->html->hparagraphs("Add Blog Post");
	}
	
	my $postdata;
	my $now = $self->um->date->now();
	my $filedate = $now->[2] . "-" . sprintf("%02d", $now->[1]) . "-" . sprintf("%02d", $now->[0]);
	
	my @categories = @{LoadFile($self->um->documentroot . "/config/categories.yaml")};
	
	my $form = $self->um->form(undef, [ "title", "body", "file", "date", "categories", "state", "type", "postid", "submit" ], $self->req->url, "POST");
	$form->p("title", { size => 40, class => "span10", style => "font-size: 20px", placeholder => "Optional Blog Post Title", id => "title" });
	$form->p("body", { type => "textarea", rows => 33, cols => 80, class => "span12", id => "body" });
	$form->p("file", { size => 30, class => "span12" });
	$form->p("date", { type => "date", includetime => 2, class => "span3", value => $self->um->date->unixtotimestamp(time) });
	$form->p("categories", { type => "checkbox", options => \@categories });
	$form->p("state", { type => "select", options => [ { "draft" => "Draft" }, { "published" => "Published" } ], class => "span12", value => "published", id => "state" });
	$form->p("type", { type => "select", options => [ { "blog" => "Blog" }, { "facebook" => "Facebook" }, { "twitter" => "Twitter" }, { "foursquare" => "Foursquare" } ], class => "span12", value => "blog" });
	$form->p("postid", { type => "hidden", value => $postid, forcevalue => 1 });
	$form->p("submit", { type => "submit", label => ($postid ? "Save Changes" : "Create New Post"), class => "btn-success", id => "postbutton" });
	
	my $submit = $self->param("submit") || "";
	if ($submit ne "") {
		
		$form->showerrors(1);

		my $validation = $form->validate;

		if (!defined $validation) {
			my $s = $form->submitted([ qw(title body file date categories state type postid) ]);

			if ($s->{categories} and ref($s->{categories}) ne "ARRAY") {
				$s->{categories} = [ $s->{categories} ];
			}
			if ($s->{tags} and ref($s->{tags}) ne "ARRAY") {
				$s->{tags} = [ $s->{tags} ];
			}
			
			my ($year, $month, $day) = split(/-/, substr($s->{date}, 0, 10), 3);

			if ($s->{postid}) {
				
				if ($s->{file} eq "") {
					$s->{file} = "$year-$month-$day-" . $self->um->makeniceurl($s->{title} || substr($s->{date}, 11, 8));
				}
				
				if ($s->{file} ne $s->{postid}) {
					deletepost($self, $s->{postid});	
				}
				
				my $niceurl = "/$year/$month/$day/" . $self->um->makeniceurl($s->{title} || substr($s->{date}, 11, 8)) . "/";
				
				savepost($self, $s->{file}, { date => $s->{date}, title => $s->{title}, type => $s->{type}, body => $s->{body}, state => $s->{state}, categories => $s->{categories}, niceurl => $niceurl });
								
				return $self->redirect_to("/admin/blog/?done=1");
				
			} else {

				if ($s->{file} eq "") {
					$s->{file} = "$year-$month-$day-" . $self->um->makeniceurl($s->{title} || substr($s->{date}, 11, 8));
				}
				
				my ($year, $month, $day) = split(/-/, substr($s->{date}, 0, 10), 3);
				my $niceurl = "/$year/$month/$day/" . $self->um->makeniceurl($s->{title} || substr($s->{date}, 11, 8)) . "/";				
				savepost($self, $s->{file}, { date => $self->um->date->unixtotimestamp(time), title => $s->{title}, type => $s->{type}, body => $s->{body}, state => $s->{state}, categories => $s->{categories}, niceurl => $s->{niceurl} });
								
				return $self->redirect_to("/admin/blog/?done=2");
				
			}
			
			
		} else {
			$output .= $self->um->getblock("form/failure", { text => (ref($validation->{FORM}) eq "ARRAY" ? join(" ", @{$validation->{FORM}}) : qq|There were some problems with your submission.| ) });
			
		}
		
	} else {
		
		if ($postid) {
			$postdata = getpost($self, $postid);
			if (!defined $postdata) {
				return $self->redirect_to("/admin/blog/?m=4");
			}
			$form->values($postdata);
						
		}
		
	}
	
	my $finalform = $form->content(undef, "admin/blog/addeditpost");
	
	$finalform =~ s!name="date-month"  class="span2"!name="date-month" class="span5"!;
	$output .= $finalform;
	
	return $self->render('admin/surround', replace => { title => ($postid ? ($postdata->{title} || "Untitled") : "Untitled"), content => $output });	
	
}

sub confirmdeleteposts {
	
	my $self = shift;
	
	my @items = $self->param("listitem");
	my $confirm = $self->param("confirm") || "";
	
	my $output = $self->um->html->hparagraphs("Delete Blog Post", "Are you sure you want to delete the following?");

	my %mapping;
	foreach my $item (@items) {		
		$mapping{$item} = getpost($self, $item)->{title};	
	}
	
	$output .= $self->um->html->paragraphs(join("<br>", map { " - " . $mapping{$_} } @items));

	foreach my $item (@items) {
		if ($confirm =~ /^Yes/) {
			deletepost($self, $item);
			$self->redirect_to("/admin/blog?m=3");			
		}
	}

	$output .= $self->um->getblock("admin/confirmdelete", { action => "/admin/blog/deletepost", hiddens => join("", map { qq|<input type="hidden" name="listitem" value="$_">| } @items) });

	if ($confirm ne "" or !@items) {
		return $self->redirect_to("/admin/blog/");
	}	

	return $self->render('admin/surround', replace => { title => "Delete Blog Post", content => $output });	
	
}

sub categories {
	
	my $self = shift;
	
	my ($output);
	
	return $self->render('admin/surround', replace => { title => "Delete Blog Post", content => $output });	
	
}

sub getpostlist {
	
	my $self = shift;
	my $filters = shift;
	my @posts;
	
	local *DIR;
	opendir(DIR, $self->um->documentroot . "/data/blog");
	while (my $file = readdir(DIR)) {
		next if ($file !~ /.md$/);

		my $post = getpost($self, $file);
		
		if ($filters->{type} and $post->{type} ne $filters->{type}) {
			next;
		}
		if ($filters->{title} and $post->{title} !~ /\Q$filters->{title}\E/i) {
			next;
		}
		if ($filters->{state} and $post->{state} ne $filters->{state}) {
			next;
		}
		
		push @posts, $post;
		
	}
	
	@posts = sort { ($b->{date} || "") cmp ($a->{date} || "") } @posts;
	
	return @posts;
	
}

sub getpost {
	
	my $self = shift;
	my $file = shift;

	$file =~ s/\.md$//;
	
	# Parse the filename		
	my ($year, $month, $day, $urltitle) = split(/-/, $file, 4);
	my $title = $self->um->reverseniceurl($urltitle);
	
	# Load the file
	if (!-e $self->um->safepath($self->um->documentroot . "/data/blog/$file.md")) {
		warn "fail load for $file";
		return undef;
	}

	my @stat = stat($self->um->documentroot . "/data/blog/$file.md");
	
	local *IN;
	open(IN, $self->um->safepath($self->um->documentroot . "/data/blog/$file.md"));
	binmode(IN, ":encoding(UTF-8)");	
	my $postdata = do { local $/; <IN> };
	close(IN);
	
	# And grab the config and YAML parse it
	$postdata =~ s/\-\-\-(.*?)\-\-\-\n//ms;
	my $postconfiglines = $1;
	my $postconfig = Load($postconfiglines);		
	
	my $id = $file;
	$id =~ s/\.md$//;
	$postconfig->{urltitle} = $title;
	$postconfig->{date} ||= "$year-$month-$day 00:00:00";
	$postconfig->{niceurl} = "/$year/$month/$day/$urltitle/";
	$postconfig->{state} ||= "published";
	$postconfig->{type} ||= "blog";
	
	return { id => $id, %{$postconfig}, body => $postdata, file => $file, lastmodified => $stat[9] };	
	
}

sub savepost {
	
	my $self = shift;
	my $file = shift;
	my $data = shift;
	
	my $nooverwrite = 0;
	if ($data->{nooverwrite}) {
		$nooverwrite = 1;
		delete $data->{nooverwrite};
	}
	
	if ($nooverwrite) {
		if (-e $self->um->safepath($self->um->documentroot . "/data/blog/$file.md")) {
			return undef;
		}
	}
	
	my $body = $data->{body};
	delete $data->{body};
	
	my $save;
	$save .= Dump($data);
	$save .= "---\n";
	$save .= $body;

	open(OUT, ">", $self->um->safepath($self->um->documentroot . "/data/blog/$file.md"));
	binmode(OUT, ":encoding(UTF-8)");	
	print OUT $save;
	close(OUT);

	return 1;
	
}

sub deletepost {
	
	my $self = shift;
	my $file = shift;
	
	unlink($self->um->safepath($self->um->documentroot . "/data/blog/$file.md"));
	
}

sub attachfile {
	
	my $self		= shift;
	
	# Check file size
	return $self->render(text => "File is too big.", status => 200) if $self->req->is_limit_exceeded;
	
	# Process uploaded file
	my $file = $self->param("file");
	my $name = $self->param("name");
	my $uid = $self->param("uid");
		
	my ($ext) = $file->filename =~ /\.([a-zA-Z]{3,4})$/;
	
	$file->move_to($self->um->documentroot() . "/public/images/$uid.$ext");
	
	$self->render(text => "Uploaded");
	
}
1;

