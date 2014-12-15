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


# Get a list of all products


my $cursor = $products_collection->query({})->fields( {'code' => 1, '_id'=>1, 'lc'=>1});

my $count = $cursor->count();

my $i = 0;
my $j = 0;
	
	print STDERR "$count products to update\n";
	
	while (my $product_ref = $cursor->next) {
        
		$i++;
		
		my $code = $product_ref->{code};
		my $id = $product_ref->{id};
		
		if (not defined $lc) {
			print STDERR "lc does not exist - updating product _id: $id - hcode $code\n";		
		}
		
		if (not defined $code) {
		
		$j++;
		
		print STDERR "code does not exist - updating product _id: $id - hcode $code\n";
		
		#$products_collection->remove({"code" => $code});
		
		# index_product($product_ref);

		# Store

		# store("$data_root/products/$path/product.sto", $product_ref);		
		# $products_collection->save($product_ref);
		}
	}

print "$i products, removed $j\n";	
	
exit(0);
