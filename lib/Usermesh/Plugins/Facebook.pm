
package Usermesh::Plugins::Facebook;

use strict;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;
use Storable qw(store retrieve);
use Facebook::Graph();

sub register {
	
	my ($self, $app) = @_;
	
	# This is where you register all the routes that this plugin will provide
	$app->routes->any('/admin/importer/facebook' => \&auth);
	$app->routes->any('/admin/importer/facebook/callback' => \&callback);

	# And this is where you can add to the sidebar menu
	$app->um->addtoadminmenu({ text => "Facebook", link => "/admin/importer/facebook/", category => "Importers" });
	
}

sub auth {
	
	my $self = shift;
	
	my ($output);
	
	my $datafile = $self->um->documentroot() . "/data/facebookauth.dat";
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$output = $self->um->html->hparagraphs("Facebook Importer", "Your Facebook account has been authorised. To import your Facebook posts, simply run the following...");
		$output .= qq|<code>| . $self->um->documentroot() . "/import-facebook.pl" . qq|</code>|;
	} else {
		$output = $self->um->html->hparagraphs("Facebook Importer", "In order to import from Facebook, you need to create an app on Facebook and then authorise it to access your account.", qq|Visit <a href="https://developers.facebook.com/apps" target="_blank">https://developers.facebook.com/apps</a>, log in with your Facebook account and then follow the instructions to create a new application. You can call it whatever you want, but be sure to choose that your application integrates via 'Website with Facebook Login' and enter the URL...|, $self->req->url->to_abs . "callback", "Once you've done that, copy and paste the App ID and App Secret into the fields below and click the Authorise button. You'll then be taken to Facebook where you'll be able to authorise the application you just created to access your account.");

		my $form = $self->um->form(undef, [ "key", "secret", "submit" ], $self->req->url, "POST");
		$form->p("key", { label => "App ID", size => 40, class => "span6" });
		$form->p("secret", { label => "App Secret", size => 40, class => "span6" });
		$form->p("submit", { type => "submit", label => "Authorise" });
		
		my $submit = $self->param("submit") || "";
		if ($submit ne "") {
			
			$form->showerrors(1);
	
			my $validation = $form->validate;
	
			if (!defined $validation) {
				my $s = $form->submitted([ qw(key secret) ]);		
							
				my %consumer_tokens = (
					app_id		=> $s->{key},
					secret		=> $s->{secret},
					postback	=> $self->req->url->to_abs . "callback",
				);
					
				my $fb = Facebook::Graph->new(%consumer_tokens);
				my $auth_url = $fb->authorize->extend_permissions(qw(read_stream))->uri_as_string;
    				
				my $keyfile = $self->um->documentroot() . "/data/facebookkey.dat";
				store { %consumer_tokens }, $keyfile;
				
				warn $auth_url;
				
				return $self->redirect_to($auth_url);

			} else {
				$output .= $self->um->getblock("form/failure", { text => (ref($validation->{FORM}) eq "ARRAY" ? join(" ", @{$validation->{FORM}}) : qq|There were some problems with your submission.| ) });
				
			}
			
		}
		
		$output .= $form->content();
		
	}
	
	return $self->render('admin/surround', replace => { title => "Facebook Importer", content => $output });
		
}

sub callback {
	
	my $self = shift;
	
	my $token = $self->param("code");
	warn $token;
	
	my $keyfile = $self->um->documentroot() . "/data/facebookkey.dat";
	my $keydata = retrieve($keyfile);
	
	my $fb = Facebook::Graph->new(%{$keydata});	
	
	my @access_tokens = $fb->request_access_token($token)->token();
	
	my $datafile = $self->um->documentroot() . "/data/facebookauth.dat";	
	
	# save the access tokens
	store \@access_tokens, $datafile;	
	
	$self->redirect_to("/admin/importer/facebook/");
	
}

1;

