
package Usermesh::Plugins::Foursquare;

use strict;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;
use Storable qw(store retrieve);
use WWW::Foursquare();

sub register {
	
	my ($self, $app) = @_;
	
	# This is where you register all the routes that this plugin will provide
	$app->routes->any('/admin/importer/foursquare' => \&auth);
	$app->routes->any('/admin/importer/foursquare/callback' => \&callback);

	# And this is where you can add to the sidebar menu
	$app->um->addtoadminmenu({ text => "Foursquare", link => "/admin/importer/foursquare/", category => "Importers" });
	
}

sub auth {
	
	my $self = shift;
	
	my ($output);
	
	my $datafile = $self->um->documentroot() . "/data/foursquareauth.dat";
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$output = $self->um->html->hparagraphs("Foursquare Importer", "Your Foursquare account has been authorised. To import your Foursquare posts, simply run the following...");
		$output .= qq|<code>| . $self->um->documentroot() . "/import-foursquare.pl" . qq|</code>|;
	} else {
		$output = $self->um->html->hparagraphs("Foursquare Importer", "In order to import from Foursquare, you need to create an app on Foursquare and then authorise it to access your account.", qq|Visit <a href="https://foursquare.com/developers/apps" target="_blank">https://foursquare.com/developers/apps</a>, log in with your Foursquare account and then follow the instructions to create a new application. You can call it whatever you want, but enter the following as the callback URL...|, $self->req->url->to_abs . "callback", "Once you've done that, copy and paste the Client ID and Client Secret into the fields below and click the Authorise button. You'll then be taken to Foursquare where you'll be able to authorise the application you just created to access your account.");

		my $form = $self->um->form(undef, [ "key", "secret", "submit" ], $self->req->url, "POST");
		$form->p("key", { label => "Client ID", size => 40, class => "span6" });
		$form->p("secret", { label => "Client Secret", size => 40, class => "span6" });
		$form->p("submit", { type => "submit", label => "Authorise" });
		
		my $submit = $self->param("submit") || "";
		if ($submit ne "") {
			
			$form->showerrors(1);
	
			my $validation = $form->validate;
	
			if (!defined $validation) {
				my $s = $form->submitted([ qw(key secret) ]);		
							
				my %consumer_tokens = (
					client_id		=> $s->{key},
					client_secret	=> $s->{secret},
					redirect_uri	=> $self->req->url->to_abs . "callback",
				);
					
				my $fs = WWW::Foursquare->new(%consumer_tokens);
				my $auth_url = $fs->get_auth_url();
				
				my $keyfile = $self->um->documentroot() . "/data/foursquarekey.dat";
				store { %consumer_tokens }, $keyfile;
				
				return $self->redirect_to($auth_url);

			} else {
				$output .= $self->um->getblock("form/failure", { text => (ref($validation->{FORM}) eq "ARRAY" ? join(" ", @{$validation->{FORM}}) : qq|There were some problems with your submission.| ) });
				
			}
			
		}
		
		$output .= $form->content();
		
	}
	
	return $self->render('admin/surround', replace => { title => "Foursquare Importer", content => $output });
		
}

sub callback {
	
	my $self = shift;
	
	my $token = $self->param("code");
	
	my $keyfile = $self->um->documentroot() . "/data/foursquarekey.dat";
	my $keydata = retrieve($keyfile);
	
	my $fs = WWW::Foursquare->new(%{$keydata});	
	
	my @access_tokens = $fs->get_access_token($token);
	
	my $datafile = $self->um->documentroot() . "/data/foursquareauth.dat";	
	
	# save the access tokens
	store \@access_tokens, $datafile;	
	
	$self->redirect_to("/admin/importer/foursquare/");
	
}

1;

