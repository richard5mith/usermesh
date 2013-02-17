Usermesh
========

Usermesh is a personal blogging platform that lets you combine blog posts (and we have a lovely editor for writing them) along with your content from Facebook, Twitter and Foursquare into a single, statically generated stream of "you".

We're all writing and producing content in lots of different places, and Usermesh lets you free it all from those external walls and pull it all into a site that's controlled by you. Not only do you get a lovely blog with everything in one place, but you also get a nice backup for the future.

Usermesh requires...

- Perl
- Mojolicious framework
- A few easily installable Perl modules from CPAN

It should be quick and simple to get started.

Visit us on the web at http://usermesh.org

INSTALLATION
============

1. Firstly, make sure you have Perl, at least 5.10.1, but 5.14+ even better
2. Install Mojolicious. This is a web framework you can read more about at http://mojolicio.us.

Run this command to download and install it...

<code>curl get.mojolicio.us | sh</code>

3. We use the following Perl modules, all of which are either installed by default with Perl or available from CPAN. http://cpan.org.

- File::Basename
- Text::Unidecode
- YAML::XS
- Net::Twitter::Lite
- WWW::Foursquare
- Facebook::Graph
- Text::Markdown
- HTML::Entities
- Time::Local
- Date::Manip
- DateTime
- DateTime::Timezone
- Digest::MD5

SETUP
=====

1. Open up usermesh.pl and find the line...

<code>app->secret('YOUR SECRET HERE');</code>

Change "YOUR SECRET HERE" to a random string of characters. As crazy as you want it to be.

2. Next, you need to create an admin password. Run the following from the usermesh folder.

<code>./setadminpassword.pl [YOURPASSWORD]</code>

Substituting your own password as a parameter for the script. 

3. Edit the config/main.yaml file in a text editor, and replace each of the x's with your site name, domain and your name. In the blogdomain field, don't put http:// or anything at the start or / at the end, just the domain.

4. Mojolicious comes with a web-server called hypnotoad. For the simplest method of running Usermesh, just do...

<code>hypnotoad usermesh.pl</code>

And it'll fire up a web-server listening on port 80. You can change this config in usermesh.pl for what port to listen on.

5. That's it. Visit http://yourdomain.com/admin in your browser and login. If you're running it on your local machine, http://127.0.0.1/admin.


SITE GENERATION
===============

Usermesh stores all your blog posts and imported content in the data/blog folder, with one file per post, all of which are Markdown files with a YAML header for meta data.

The generatestatic.pl script takes all of those files and the templates in the skin folder and spits out a complete, static version of your site in the public folder. All you need to do then is upload the contents of the public folder somewhere and that's your site. Or alternatively, if you're running the admin on the same server as you want to host your site on, just go to the root of your domain and those static files will be served up by Usermesh.


IMPORTERS
=========

We currently hve importers for Facebook, Twitter and Foursquare.

With the Usermesh admin, visit the links for these on the left sidebar. Follow the instructions there on how to create an app within each of those respective services developer areas and authorise your account to access them.

Next, simple run the import-facebook.pl, import-twitter.pl or import-foursquare.pl scripts. Each of these will then connect to the service API, download all your content, and create the posts within your data/blog folder. You can set each of these scripts up in your cron to run automatically and keep your content up to date.

One thing to note, the Twitter API will only let you access the last 3,500 of your tweets. So if you have more than that, I'm afraid they won't all end up on your site.


FOURSQUARE MAPS
===============

We render maps with Leaflet. Visit cloudmade.com to get an API key for the tiles, put that in your config file.


EXAMPLE
=======

My own blog is powered by Usermesh. http://richardsmith.me/


CONTACT
=======

All of this is early days, including the documentation. If you have any questions, contact me at richard@square8.com.


LICENSE
=======

Usermesh is licensed under GPLv2. http://www.gnu.org/licenses/gpl-2.0.txt

