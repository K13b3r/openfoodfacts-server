#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

use strict;
use utf8;

use Blogs::Config qw/:all/;
use Blogs::Store qw/:all/;
use Blogs::Index qw/:all/;
use Blogs::Display qw/:all/;
use Blogs::Tags qw/:all/;
use Blogs::Users qw/:all/;
use Blogs::Images qw/:all/;
use Blogs::Lang qw/:all/;
use Blogs::Mail qw/:all/;
use Blogs::Products qw/:all/;
use Blogs::Food qw/:all/;
use Blogs::Ingredients qw/:all/;
use Blogs::Images qw/:all/;


use CGI qw/:cgi :form escapeHTML/;
use URI::Escape::XS;
use Storable qw/dclone/;
use Encode;
use JSON;

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
my $server_endpoint = "https://hooks.slack.com/services/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";


sub send_msg($) {

	my $msg = shift;
	
# set custom HTTP request header fields
	my $req = HTTP::Request->new(POST => $server_endpoint);
	$req->header('content-type' => 'application/json');
	 
	# add POST data to HTTP request body
	my $post_data = '{"channel": "#bots", "username": "checkbot", "text": "' . $msg . '", "icon_emoji": ":hamster:" }';
	$req->content($post_data);
	 
	my $resp = $ua->request($req);
	if ($resp->is_success) {
		my $message = $resp->decoded_content;
		print "Received reply: $message\n";
	}
	else {
		print "HTTP POST error code: " .  $resp->code . "\n";
		print "HTTP POST error message: " . $resp->message . "\n";
	}
	
}

my $cursor = $products_collection->query({})->fields({ code => 1 });;
my $count = $cursor->count();
	
	print STDERR "$count products to update\n";
	
	while (my $product_ref = $cursor->next) {
        
		
		my $code = $product_ref->{code};
		my $path = product_path($code);
		
		print STDERR "updating product $code\n";
		
		$product_ref = retrieve_product($code);
		
		if (not defined $product_ref) {
			print "product code $code not found\n";
		}
		else {
		
			if (defined $product_ref->{nutriments}) {
			
				next if has_tag($product_ref, "labels", "fr:informations-nutritionnelles-incorrectes");
				next if has_tag($product_ref, "labels", "en:incorrect-nutrition-facts-on-label");
				
				my $name = get_fileid($product_ref->{product_name});
				my $brands = get_fileid($product_ref->{brands});
			
				foreach my $nid (keys %{$product_ref->{nutriments}}) {
					next if $nid =~ /_/;
					
					if (($nid !~ /energy/) and ($nid !~ /footprint/) and ($product_ref->{nutriments}{$nid . "_100g"} > 105)) {
					
						my $msg = "Product <http://world.openfoodfacts.org/product/$code> ($name / $brands) : $nid = "
						. $product_ref->{nutriments}{$nid . "_100g"} . "g / 100g";
						
						print "$code : " . $msg . "\n";
						
						send_msg($msg);
#exit;						
			
					}
				}
				
				if ((defined $product_ref->{nutriments}{"carbohydrates_100g"}) and (($product_ref->{nutriments}{"sugars_100g"} + $product_ref->{nutriments}{"starch_100g"}) > ($product_ref->{nutriments}{"carbohydrates_100g"}) + 0.001)) {
				
						my $msg = "Product <http://world.openfoodfacts.org/product/$code> ($name / $brands) : sugars (" . $product_ref->{nutriments}{"sugars_100g"}  . ") + starch (" .  $product_ref->{nutriments}{"starch_100g"}. ") > carbohydrates (" . $product_ref->{nutriments}{"carbohydrates_100g"}  . ")";
						
						print "$code : " . $msg . "\n";
						
						send_msg($msg);				
				
				}
			}		
		
		}
	}

exit(0);

