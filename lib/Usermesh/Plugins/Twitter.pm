
package Usermesh::Plugins::Twitter;

use strict;

use Mojo::Base 'Mojolicious::Plugin';

use Data::Dumper;
use Storable qw(store retrieve);
use Net::Twitter::Lite();

sub register {
	
	my ($self, $app) = @_;
	
	# This is where you register all the routes that this plugin will provide
	$app->routes->any('/admin/importer/twitter' => \&auth);
	$app->routes->any('/admin/importer/twitter/callback' => \&callback);

	# And this is where you can add to the sidebar menu
	$app->um->addtoadminmenu({ text => "Twitter", link => "/admin/importer/twitter/", category => "Importers" });
	
}

sub auth {
	
	my $self = shift;
	
	my ($output);
	
	my $datafile = $self->um->documentroot() . "/data/twitterauth.dat";
	my $access_tokens = eval { retrieve($datafile) } || [];
	
	if ( @$access_tokens ) {
		$output = $self->um->html->hparagraphs("Twitter Importer", "Your Twitter account has been authorised. To import your Twitter posts, simply run the following...");
		$output .= qq|<code>| . $self->um->documentroot() . "/import-twitter.pl" . qq|</code>|;
	} else {
		$output = $self->um->html->hparagraphs("Twitter Importer", "In order to import from Twitter, you need to create an app on Twitter and then authorise it to access your account.", qq|Visit <a href="https://dev.twitter.com/apps" target="_blank">https://dev.twitter.com/apps</a>, log in with your Twitter account and then follow the instructions to create a new application. You can call it whatever you want, but enter the following as the callback URL...|, $self->req->url->to_abs . "callback", "Once you've done that, copy and paste the Consumer key and Consumer Secret into the fields below and click the Authorise button. You'll then be taken to Twitter where you'll be able to authorise the application you just created to access your account.");

		my $form = $self->um->form(undef, [ "key", "secret", "submit" ], $self->req->url, "POST");
		$form->p("key", { label => "Consumer Key", size => 40, class => "span6" });
		$form->p("secret", { label => "Consumer Secret", size => 40, class => "span6" });
		$form->p("submit", { type => "submit", label => "Authorise" });
		
		my $submit = $self->param("submit") || "";
		if ($submit ne "") {
			
			$form->showerrors(1);
	
			my $validation = $form->validate;
	
			if (!defined $validation) {
				my $s = $form->submitted([ qw(key secret) ]);		
							
				my %consumer_tokens = (
					consumer_key    => $s->{key},
					consumer_secret => $s->{secret},
					legacy_lists_api => 0,
				);
					
				my $nt = Net::Twitter::Lite->new(%consumer_tokens);
				my $auth_url = $nt->get_authorization_url(callback => $self->req->url->to_abs . "callback");
				
				my $keyfile = $self->um->documentroot() . "/data/twitterkey.dat";
				store { %consumer_tokens, token => $nt->request_token, token_secret => $nt->request_token_secret }, $keyfile;
				
				return $self->redirect_to($auth_url);
					
			} else {
				$output .= $self->um->getblock("form/failure", { text => (ref($validation->{FORM}) eq "ARRAY" ? join(" ", @{$validation->{FORM}}) : qq|There were some problems with your submission.| ) });
				
			}
			
		}
		
		$output .= $form->content();
		
	}
	
	return $self->render('admin/surround', replace => { title => "Twitter Importer", content => $output });
		
}

sub callback {
	
	my $self = shift;
	
	my $token = $self->param("oauth_token");
	my $verify = $self->param("oauth_verifier");
	
	my $keyfile = $self->um->documentroot() . "/data/twitterkey.dat";
	my $keydata = retrieve($keyfile);
	
	my $nt = Net::Twitter::Lite->new(%{$keydata});	
	$nt->request_token($keydata->{token});
	$nt->request_token_secret($keydata->{token_secret});
	
	my @access_tokens = $nt->request_access_token(verifier => $verify);
	
	my $datafile = $self->um->documentroot() . "/data/twitterauth.dat";	
	
	# save the access tokens
	store \@access_tokens, $datafile;	
	
	$self->redirect_to("/admin/importer/twitter/");
	
}

1;

