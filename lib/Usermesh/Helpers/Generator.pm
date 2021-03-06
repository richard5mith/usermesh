
package Usermesh::Helpers::Generator;

use strict;

use File::Path qw(make_path);
use Text::Unidecode qw(unidecode);
use XML::RSS();

use Usermesh::Plugins::Blog();

sub new {

	my $proto		= shift;
	my $class		= ref($proto) || $proto;

	my $self		= bless {}, $class;

	$self->{UM}		= shift;
	$self->{BLOG}	= Usermesh::Plugins::Blog->new($self->{UM});
	
	return $self;

}

sub um {

	my $self = shift;	
	
	return $self->{UM};
	
}

sub run {
	
	my $self		= shift;
	my $force		= shift;
	
	my $skin = $self->um->{CONFIG}->{skin} || "base";
	
	my $singleheader = $self->um->getblock("public/$skin/single_header");
	my $singlefooter = $self->um->getblock("public/$skin/single_footer");
	my $surround = $self->um->getblock("public/$skin/surround");
		
	my $totalwritten = 0;
	my (@allposts, %allcategories, %categoryposts);
	opendir(DATA, $self->um->documentroot . "/data");
	while (my $folder = readdir(DATA)) {
		
		next if ($folder =~ /^\./);
			
		# work out all the categories of post we have
		opendir(POSTS, $self->um->documentroot . "/data/$folder");
		while (my $post = readdir(POSTS)) {
			next if ($post !~ /\.md$/);
	
			my $postdata = $self->{BLOG}->getpost($post);
			next if ($postdata->{state} eq "draft");
			
			map { $allcategories{$_} = 1 } @{$postdata->{categories}};		
		}
		
		# go through all the posts we have and create pages for them
		opendir(POSTS, $self->um->documentroot . "/data/$folder");	
		while (my $post = readdir(POSTS)) {
			next if ($post !~ /\.md$/);
	
			my $postdata = $self->{BLOG}->getpost($post);
			next if ($postdata->{state} eq "draft");
	
			# format the post
			$postdata->{body} = $self->um->html->formathtml({ text => $postdata->{body}, markdown => 1, textplugins => 1, links => 1 });
			
			# create the html for the post itself
			my $posthtml = $self->um->getblock("public/$skin/post" . ($postdata->{type} ne "blog" ? "_$postdata->{type}" : "_blog"), { %{$postdata}, categories => $self->drawcategories($postdata->{categories}, "short") });		
			
			# push it into the list of all of them
			push @allposts, { html => $posthtml, date => $postdata->{date}, data => $postdata };
			
			# and push it into a list for each of the categories it's in
			foreach my $cat (@{$postdata->{categories}}) {
				push @{$categoryposts{$cat}}, { html => $posthtml, date => $postdata->{date} };
			}
			
			# Work out the page title
			$postdata->{title} = ($postdata->{title} ? $postdata->{title} : $self->um->date->formatdate($postdata->{date}, "D4, M4 D1ds Y2, h2:m2"));
			
			# Create the final page for a single post
			my $finalpage = $self->um->replaceinto($surround, { content => $singleheader . $posthtml . $singlefooter, %{$postdata}, categories => $self->drawcategories([keys %allcategories]) });
			
			my $result = $self->writepostpage($post, $postdata, $finalpage, $force);
			
			$totalwritten += $result;
			
		}
		closedir(POSTS);
		
	}
		
	if ($totalwritten > 0) {
		$self->writelistpage([ @allposts ], "", undef, \%allcategories);
		
		foreach my $cat (keys %categoryposts) {
			$self->writelistpage([ @{$categoryposts{$cat}} ], $self->um->makeniceurl($cat), $cat, \%allcategories);
		}
		
		$self->generaterss({ posts => [ reverse @allposts[-15..-1] ] });
	}
		
	return $totalwritten;
	
}

sub writelistpage {
	
	my $self				= shift;
	my $posts				= shift;
	my $subfolder			= shift;
	my $categoryhighlight	= shift;
	my $allcategories		= shift;
	
	my $skin = $self->um->{CONFIG}->{skin} || "base";
	
	if ($subfolder ne "") {
		$subfolder = "/$subfolder";
	}
	
	my $homeheader = $self->um->getblock("public/$skin/home_header") || "";
	my $homefooter = $self->um->getblock("public/$skin/home_footer") || "";	
	my $categoryheader = $self->um->getblock("public/$skin/category_header") || "";
	my $categoryfooter = $self->um->getblock("public/$skin/category_footer") || "";
	my $surround = $self->um->getblock("public/$skin/surround");
	
	my $pagenav = $self->um->getblock("public/$skin/pagenav_surround");	
	my $olderhtml = $self->um->getblock("public/$skin/pagenav_older");
	my $newerhtml = $self->um->getblock("public/$skin/pagenav_newer");
	
	my $totalposts = $#{$posts} + 1;
	my $totalpages = $self->um->html->countpages($totalposts, 15);
	
	@{$posts} = sort { $b->{date} cmp $a->{date} } @{$posts};
	my $pagenumber = 1;
	while (@{$posts}) {
	
		my $pagedata = "";
		my @posts = splice(@{$posts}, 0, 15);
		foreach my $post (@posts) {
			$pagedata .= $post->{html};	
		}
		
		my $pagefolder = "";
		if ($pagenumber == 1) {
			$pagefolder = "";
		} else {
			$pagefolder = "page-$pagenumber";
		}
		my $older = "$subfolder/page-" . ($pagenumber + 1) . "/index.html";
		my $newer = "$subfolder/page-" . ($pagenumber - 1) . "/index.html";
		
		$newer = "$subfolder/index.html" if ($pagenumber == 2); 
		$newer = "" if ($pagenumber == 1);
		$older = "" if ($pagenumber == $totalpages);
		
		my $pagenavcomplete = $self->um->replaceinto($pagenav, { older => ($older ? $self->um->replaceinto($olderhtml, { link => $older }) : ""), newer => ($newer ? $self->um->replaceinto($newerhtml, { link => $newer }) : "") });
		
		my $pagecontent;
		if ($pagenumber == 1) {
			$pagecontent = $self->um->replaceinto($homeheader, { pagenav => $pagenavcomplete }) . $pagedata . $self->um->replaceinto($homefooter, { pagenav => $pagenavcomplete });
		} else {
			$pagecontent = $self->um->replaceinto($categoryheader, { pagenav => $pagenavcomplete }) . $pagedata . $self->um->replaceinto($categoryfooter, { pagenav => $pagenavcomplete });
		}
		
		my $finalpage = $self->um->replaceinto($surround, { content => $pagecontent, title => $self->um->{CONFIG}->{blogname} . ($pagefolder ? " - Page $pagenumber" : ""), categories => $self->drawcategories([keys %{$allcategories}], undef, $categoryhighlight) });
		
		if ($subfolder) {
			mkdir($self->um->documentroot . "/public$subfolder");
		}		
		mkdir($self->um->documentroot . "/public$subfolder/$pagefolder");
		
		open(OUT, ">", $self->um->documentroot . "/public$subfolder/$pagefolder/index.html");
		binmode(OUT, ":encoding(UTF-8)");
		print OUT $finalpage;
		close(OUT);
		
		$pagenumber++;
	
	}

}

# Write a post page
sub writepostpage {
	
	my $self		= shift;	
	my $post		= shift;
	my $postdata	= shift;
	my $finalpage	= shift;
	my $force		= shift;
	
	my ($year, $month, $day) = split(/-/, substr($postdata->{date}, 0, 10));

	my @stat = stat($self->um->documentroot . "/public/$postdata->{niceurl}/index.html");
	if ($postdata->{lastmodified} < $stat[9] and $force ne "1" and $force ne $postdata->{file} and -e $self->um->documentroot . "/public/$postdata->{niceurl}/index.html") {
		return;
	}
	
	make_path($self->um->documentroot . "/public/$postdata->{niceurl}");
	
	open(OUT, ">", $self->um->documentroot . "/public/$postdata->{niceurl}/index.html");
	binmode(OUT, ":encoding(UTF-8)");
	print OUT $finalpage;
	close(OUT);

	return 1;	
	
}

# Draw the categories on a post or on a surround
sub drawcategories {

	my $self		= shift;	
	my $list		= shift;
	my $mode		= shift;
	my $highlight	= shift;
	
	return if ($#{$list} == -1);

	my $skin = $self->um->{CONFIG}->{skin} || "base";
	
	my ($template, $sep);
	if ($mode eq "short") {
		$template = $self->um->getblock("public/$skin/categoryline_short");
		$sep = ", ";
	} else {
		$template = $self->um->getblock("public/$skin/categoryline");
		$sep = "";		
	}
	
	return join($sep, map { $self->um->replaceinto($template, { link => "/" . $self->um->makeniceurl($_) . "/", name => $_, highlight => ($highlight eq $_ ? qq| class="active"| : "") }) } sort { $a cmp $b } @{$list});
	
}

sub generaterss {

	my $self	= shift;	
	my $p		= shift;

	my $rss = XML::RSS->new(version => '1.0');

	$rss->add_module(prefix => "content", uri => "http://purl.org/rss/1.0/modules/content/");

	my $first = 1;
	my ($lastdate);
	foreach my $row (@{$p->{posts}}) {
		my $data = $row->{data};
		
		my $text = unidecode($data->{body});

		$rss->add_item(	title		=>	$data->{title} || $data->{urltitle},
						link		=>	"http://" . $self->um->{CONFIG}->{blogdomain} . $data->{niceurl},

						description => $text,
						dc			=>	{
											creator => $self->um->{CONFIG}->{blogauthor},
											date	=> $self->makerssdate($row->{date}),
										});

		if ($first) {
			$lastdate = $row->{date};
			$first = 0;
		}
	}

	$rss->channel(	title			=>	$self->um->{CONFIG}->{blogname},
					link			=>	"http://" . $self->um->{CONFIG}->{blogdomain} . "/",
					description		=>	$self->um->{CONFIG}->{blogname} . " RSS Feed",
					dc				=>	{
											date => $self->makerssdate($lastdate),
										} );

	open(OUT, ">", $self->um->documentroot . "/public/rss/index.rss");
	binmode(OUT, ":encoding(UTF-8)");
	print OUT $rss->as_string;
	close(OUT);

}

sub makerssdate {

	my $self	= shift;
	my $date	= shift;

	return substr($date, 0, 10) . "T" . substr($date, 11, 5) . "+00:00";

}

1;

