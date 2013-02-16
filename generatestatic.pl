#!/usr/bin/env perl

# Generates the static version of your site
# Run this whenever you want to make sure everything is up to date

use strict;

use Data::Dumper;
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";
use File::Path qw(make_path);
use Text::Unidecode qw(unidecode);
use XML::RSS();

use Usermesh();
use Usermesh::Plugins::Templates();
use Usermesh::Plugins::Blog();
use Usermesh::Helpers::Html();

my $um = Usermesh->new();
my $templates = Usermesh::Plugins::Templates->new($um);
my $blog = Usermesh::Plugins::Blog->new($um);
my $html = Usermesh::Helpers::Html->new($um);

#===== CONFIG
my $blogname = $um->{CONFIG}->{blogname};
my $blogdomain = $um->{CONFIG}->{blogdomain};
my $blogauthor = $um->{CONFIG}->{blogauthor};
my $skin = $um->{CONFIG}->{skin} || "base";
#===== CONFIG

my $totalwritten = 0;
my (@allposts, %allcategories, %categoryposts);
opendir(DATA, $um->documentroot . "/data");
while (my $folder = readdir(DATA)) {
	
	next if ($folder =~ /^\./);
		
	opendir(POSTS, $um->documentroot . "/data/$folder");
	while (my $post = readdir(POSTS)) {
		next if ($post !~ /\.md$/);

		my $postdata = $blog->getpost($post);
		next if ($postdata->{state} eq "draft");
		
		map { $allcategories{$_} = 1 } @{$postdata->{categories}};		
	}
	
	opendir(POSTS, $um->documentroot . "/data/$folder");	
	while (my $post = readdir(POSTS)) {
		next if ($post !~ /\.md$/);

		my $postdata = $blog->getpost($post);
		next if ($postdata->{state} eq "draft");

		$postdata->{body} = $um->html->formathtml({ text => $postdata->{body}, markdown => 1, textplugins => 1 });
		my $posthtml = $templates->getblock("public/$skin/post" . ($postdata->{type} ne "blog" ? "_$postdata->{type}" : ""), { %{$postdata}, categories => drawcategories($postdata->{categories}, "short") });		
		
		push @allposts, { html => $posthtml, date => $postdata->{date}, data => $postdata };
		foreach my $cat (@{$postdata->{categories}}) {
			push @{$categoryposts{$cat}}, { html => $posthtml, date => $postdata->{date} };
		}
		
		$postdata->{title} = ($postdata->{title} ? "$postdata->{title} - $blogname" : $um->date->formatdate($postdata->{date}, "D4, M4 D1ds Y2, h2:m2") . " - " . $blogname);
		my $finalpage = $templates->getblock("public/$skin/surround", { content => $posthtml . $templates->getblock("public/$skin/postpagefooter"), %{$postdata}, categories => drawcategories([keys %allcategories]) });
		
		my $result = writepostpage($post, $postdata, $finalpage);
		
		$totalwritten += $result;
		
	}
	closedir(POSTS);
	
}

print "Generated $totalwritten post pages\n";

if ($totalwritten > 0) {
	print "Generating all posts index pages...\n";
	writelistpage([ @allposts ], "");
	
	print "Generating category index pages...\n";
	foreach my $cat (keys %categoryposts) {
		writelistpage([ @{$categoryposts{$cat}} ], $um->makeniceurl($cat), $cat);
	}
	
	print "Generating RSS...\n";
	generaterss({ posts => [ reverse @allposts[-15..-1] ] });
}

print "Done.\n";

#===== FUNCTIONS

# Write the listing pages
sub writelistpage {
	
	my $posts = shift;
	my $subfolder = shift;
	my $categoryhighlight = shift;
	
	if ($subfolder ne "") {
		$subfolder = "/$subfolder";
	}
	
	my $olderhtml = $templates->getblock("public/$skin/older");
	my $newerhtml = $templates->getblock("public/$skin/newer");
	
	my $totalposts = $#{$posts} + 1;
	my $totalpages = $html->countpages($totalposts, 15);
	
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
		
		$newer = "/index.html" if ($pagenumber == 2); 
		$newer = "" if ($pagenumber == 1);
		$older = "" if ($pagenumber == $totalpages);
		
		my $indexhead = $templates->getblock("public/$skin/pagenav", { older => ($older ? $templates->replaceinto($olderhtml, { link => $older }) : ""), newer => ($newer ? $templates->replaceinto($newerhtml, { link => $newer }) : "") });
		my $indexfoot = $templates->getblock("public/$skin/pagenav", { older => ($older ? $templates->replaceinto($olderhtml, { link => $older }) : ""), newer => ($newer ? $templates->replaceinto($newerhtml, { link => $newer }) : "") });
		
		my $finalpage = $templates->getblock("public/$skin/surround", { content => $indexhead . $pagedata . $indexfoot, title => "$blogname" . ($pagefolder ? " - Page $pagenumber" : ""), categories => drawcategories([keys %allcategories], undef, $categoryhighlight) });
		
		if ($subfolder) {
			mkdir($um->documentroot . "/public$subfolder");
		}		
		mkdir($um->documentroot . "/public$subfolder/$pagefolder");
		
		open(OUT, ">", $um->documentroot . "/public$subfolder/$pagefolder/index.html");
		binmode(OUT, ":encoding(UTF-8)");
		print OUT $finalpage;
		close(OUT);
		
		$pagenumber++;
	
	}

}

# Write a post page
sub writepostpage {
	
	my $post = shift;
	my $postdata = shift;
	my $finalpage = shift;
	
	my ($year, $month, $day) = split(/-/, substr($postdata->{date}, 0, 10));

	my @stat = stat($um->documentroot . "/public/$postdata->{niceurl}/index.html");
	if ($postdata->{lastmodified} < $stat[9] and $ARGV[0] ne "force" and $ARGV[0] ne $postdata->{file} and -e $um->documentroot . "/public/$postdata->{niceurl}/index.html") {
		return;
	}
	
	print "Generating $postdata->{niceurl}\n";
	make_path($um->documentroot . "/public/$postdata->{niceurl}");
	
	open(OUT, ">", $um->documentroot . "/public/$postdata->{niceurl}/index.html");
	binmode(OUT, ":encoding(UTF-8)");
	print OUT $finalpage;
	close(OUT);

	return 1;	
	
}

# Draw the categories on a post or on a surround
sub drawcategories {

	my $list = shift;
	my $mode = shift;
	my $highlight = shift;
	
	return if ($#{$list} == -1);
	
	my ($template, $sep);
	if ($mode eq "short") {
		$template = $templates->getblock("public/$skin/categorylineshort");
		$sep = ", ";
	} else {
		$template = $templates->getblock("public/$skin/categoryline");
		$sep = "";		
	}
	
	return join($sep, map { $templates->replaceinto($template, { link => "/" . $um->makeniceurl($_) . "/", name => $_, highlight => ($highlight eq $_ ? qq| class="active"| : "") }) } sort { $a cmp $b } @{$list});
	
}

sub generaterss {

	my $p					= shift;

	my $rss = XML::RSS->new(version => '1.0');

	$rss->add_module(prefix => "content", uri => "http://purl.org/rss/1.0/modules/content/");

	my $first = 1;
	my ($lastdate);
	foreach my $row (@{$p->{posts}}) {
		my $data = $row->{data};
		
		my $text = unidecode($data->{body});

		$rss->add_item(	title		=>	$data->{title} || $data->{urltitle},
						link		=>	"http://$blogdomain$data->{niceurl}",

						description => $text,
						dc			=>	{
											creator => $blogauthor,
											date	=> makerssdate($row->{date}),
										});

		if ($first) {
			$lastdate = $row->{date};
			$first = 0;
		}
	}

	$rss->channel(	title			=>	$blogname,
					link			=>	"http://$blogdomain/",
					description		=>	"$blogname RSS Feed",
					dc				=>	{
											date => makerssdate($lastdate),
										} );

	open(OUT, ">", $um->documentroot . "/public/rss/index.rss");
	binmode(OUT, ":encoding(UTF-8)");
	print OUT $rss->as_string;
	close(OUT);

}

sub makerssdate {

	my $date				= shift;

	return substr($date, 0, 10) . "T" . substr($date, 11, 5) . "+00:00";

}

