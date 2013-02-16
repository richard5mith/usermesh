#!/usr/bin/env perl

use Mojolicious::Lite;

use Digest::MD5 qw(md5_hex);
use File::Basename 'dirname';
use lib dirname( __FILE__ ) . "/lib";

# SET THIS
app->secret('YOUR SECRET HERE');
# SET THIS

app->config(hypnotoad => {listen => ['http://*:80'], proxy => 1});
app->types->type(rss => 'application/xhtml+xml');

use Usermesh();
my $um = Usermesh->new(app);
	
helper um => sub { 
	my $self = shift;

	$um->setrequest($self);
	
	return $um;
};

helper config => sub {
	
	my $self = shift;

	return $um->{CONFIG};	
	
};

# Load all the plugins
opendir(PLUGINDIR, dirname(__FILE__) . "/lib/Usermesh/Plugins");
while(my $file = readdir(PLUGINDIR)) {
	next if ($file !~ /\.pm$/);
	$file =~ s/\.pm$//;
	plugin "Usermesh::Plugins::$file";
}
closedir(PLUGINDIR);


get "/" => sub {
	
	my $self = shift;
	
	return $self->redirect_to('/index.html');
	
};

group {

	under '/admin' => sub {
	
		my $self = shift;
	
		if ($self->session->{auth} eq $self->config->{adminpassword}) {
			return 1;
		}
				
		$self->redirect_to("/login");
		
		return undef;
      
	};
	
	get "/" => sub {
		
		my $self = shift;
	
		my ($output);
		
		$output .= $self->um->html->hparagraphs("Hello!");
		
		$output .= $self->um->html->h3paragraphs("Current Drafts");	
		$output .= $self->draftposts();	
		
		$output .= $self->um->html->h3paragraphs("Recent Posts");
		$output .= $self->recentposts();	
		
		return $self->render('admin/surround', replace => { title => "Home", content => $output });
	
	};

};

get "/login" => sub {
	
	my $self = shift;
	
	my ($error);
	
	my $e = $self->param("e");
	
	if ($e eq "1") {
		$error = qq|<div class="alert alert-error">Invalid password</div>|;
	}
	
	return $self->render('admin/login', replace => { title => "Login", error => $error });
	
};

post "/login/auth" => sub {
	
	my $self = shift;
	
	my $password = $self->param("password");
	my $hashedpassword = md5_hex(md5_hex($password));
	
	if ($hashedpassword eq $self->config->{adminpassword}) {		
		$self->session->{auth} = $hashedpassword;
		
		$self->redirect_to("/admin/");
		
	} else {			
		$self->redirect_to("/login?e=1");	
	}
	
};

get "/logout" => sub {
	
	my $self = shift;
	
	$self->session->{auth} = undef;
	
	return $self->redirect_to('/');
	
};


get "/rss" => sub {
	
	my $self = shift;
	
	$self->render_static('rss/index.rss');
	
};

get "*page" => sub {
	
	my $self = shift;
	
	if ($self->param("page") !~ m!/index.html!) {
		return $self->redirect_to($self->param("page") . "/index.html");
	} else {
		return return $self->render_not_found;
	}
	
};

app->start;

