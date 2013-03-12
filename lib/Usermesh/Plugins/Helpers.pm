
package Usermesh::Plugins::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;

sub register {

	my ($self, $app) = @_;
		
	$app->helper(admin_sidebar => sub {
	
		my $self		= shift;
		my $p			= shift;
		
		my $filter = $p->{filter};
		my $hidecategories = $p->{hidecategories};
				
		my ($sidebar);
		my $lastcategory = "";
		foreach my $item (@{$self->um->{ADMINMENU}}) {
			next if ($filter and !$item->{$filter});
			
			if ($item->{category} ne $lastcategory) {
				if (!$hidecategories) {
					$sidebar .= qq|<li class="nav-header">$item->{category}</li>|;
				}
			}
			$sidebar .= qq|<li| . (($self->stash("base") || $self->req->url) eq $item->{link} ? qq| class="active"| : "") . qq|><a href="$item->{link}">| . ($filter ? ($item->{$filter . "text"} || $item->{text}) : $item->{text}) . qq|</a></li>|;
			
			$lastcategory = $item->{category};
		}
		
		return $sidebar;
		
	});
	
	$app->helper(showmap => sub {
	
		my $self		= shift;
		my $p			= shift;

		$p->{id} = $self->{mapid}++;
		$p->{apikey} = $self->um->{CONFIG}->{cloudmadeapikey};
		
		return $self->um->getblock("public/" . $self->um->{CONFIG}->{skin} . "/post_foursquare_map", $p);
		
	});
		
}

1;

