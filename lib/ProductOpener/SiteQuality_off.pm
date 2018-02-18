﻿# This file is part of Product Opener.
#
# Product Opener
# Copyright (C) 2011-2018 Association Open Food Facts
# Contact: contact@openfoodfacts.org
# Address: 21 rue des Iles, 94100 Saint-Maur des Fossés, France
#
# Product Opener is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package ProductOpener::SiteQuality;

use utf8;
use Modern::Perl '2012';
use Exporter    qw< import >;




BEGIN
{
	use vars       qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT = qw();	# symbols to export by default
	@EXPORT_OK = qw(
	
			
					);	# symbols to export on request
	%EXPORT_TAGS = (all => [@EXPORT_OK]);
}

use vars @EXPORT_OK ;

use ProductOpener::Store qw/:all/;
use ProductOpener::Tags qw/:all/;


my @baby_food_brands = qw(
Gallia
Bledina
Modilac
Guigoz
Milumel
Hipp
Babybio
Novalac
Premibio
Picot
Bledilait
Carrefour-baby
Pommette
Laboratoires-guigoz
Nidal
Lactel-eveil
Holle
Mots-d-enfants
Laboratoire-guigoz
Bledidej
Bebe-nestle
Laboratoire-gallia
Gilbert
Hipp-biologique
U-tout-petits
Milupa
Nestle-bebe
Blediner
Guiguoz
Laboratoires-picot
Nutricia
P-tit-souper
P-tit-dej-croissance
P-tit-dej
Sodiaal
Premichevre
Auchan-baby
Aptamil
Candia-croissance
Lactel-lait-pour-nourrisson
Croissance
Biostime
Premilait
Envia
Babysoif
Capricare
France-lait
Candia-baby
Physiolac
Topfer
);


my %baby_food_brands = ();

foreach my $brand (@baby_food_brands) {

	my $brandid = get_fileid($brand);
	$baby_food_brands{$brandid} = 1;

}


sub detect_categories ($) {

	my $product_ref = shift;

	# match on fr product name, generic name, ingredients
	my $match_fr = "";

	(defined $product_ref->{product_name}) and $match_fr .= " " . $product_ref->{product_name};
	(defined $product_ref->{product_name_fr}) and $match_fr .= "  " . $product_ref->{product_name_fr};
	
	(defined $product_ref->{generic_name}) and $match_fr .= " " . $product_ref->{generic_name};
	(defined $product_ref->{generic_name_fr}) and $match_fr .= "  " . $product_ref->{generic_name_fr};	
	
	(defined $product_ref->{ingredients_text}) and $match_fr .= " " . $product_ref->{ingredients_text};
	(defined $product_ref->{ingredients_text_fr}) and $match_fr .= "  " . $product_ref->{ingredients_text_fr};

	
	# try to identify baby milks 	
	
	if ($match_fr =~ /lait ([^,-]* )?(suite|croissance|infantile|bébé|bebe|nourrisson|nourisson|age|maternise|maternisé)/i) {
		if (not has_tag($product_ref, "categories", "en:baby-milks")) {
			push $product_ref->{quality_tags}, "detected-category-from-name-ingredients-en-baby-milks";
		}
	}
	
	if (defined $product_ref->{brands_tags}) {
		foreach my $brandid (@{$product_ref->{brands_tags}}) {
			if (defined $baby_food_brands{$brandid}) {
				push $product_ref->{quality_tags}, "detected-category-from-brand-ingredients-en-baby-foods";
				last;
			}
		}
	}
	
}


sub check_ingredients($) {

	my $product_ref = shift;

	
	# Multiple languages in ingredient lists
	
	my $nb_languages = 0;
	
	($product_ref->{ingredients_text} =~ /\b(ingrédients|sucre|eau|sel|farine)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(sugar|salt|flour|milk)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(ingrediënten|suiker|zout|bloem)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(ingredientes|azucar|agua|sal|harina)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(zutaten|Zucker|Salz|Wasser|Mehl)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(açúcar|farinha|água)\b/i) and $nb_languages++;
	($product_ref->{ingredients_text} =~ /\b(ingredienti|zucchero|farina|acqua)\b/i) and $nb_languages++;
	
	
	if ($nb_languages > 1) {
			foreach my $max (5, 4, 3, 2, 1) {
				if ($nb_languages > $max) {
					push $product_ref->{quality_tags}, "ingredients-number-of-languages-above-$max";
				}
			}		
		push $product_ref->{quality_tags}, "ingredients-number-of-languages-$nb_languages";
	}
	
	if ((defined $product_ref->{ingredients_n}) and ( $product_ref->{ingredients_n} > 0)) {	
	
			my $score = $product_ref->{unknown_ingredients_n} * 2 - $product_ref->{ingredients_n};
			
			foreach my $max (50, 40, 30, 20, 10, 5, 0) {
				if ($score > $max) {
					push $product_ref->{quality_tags}, "ingredients-unknown-score-above-$max";
					last;
				}
			}			
	
			foreach my $max (100, 90, 80, 70, 60, 50) {
				if (($product_ref->{unknown_ingredients_n} / $product_ref->{ingredients_n}) >= ($max / 100)) {
					push $product_ref->{quality_tags}, "ingredients-$max-percent-unknown";
					last;
				}
			}
	}
	
	
	
	if (defined $product_ref->{ingredients_tags}) {	
		
		my $max_length = 0;
		
		foreach my $ingredient_tag (@{$product_ref->{ingredients_tags}}) {
			my $length = length($ingredient_tag);
			$length > $max_length and $max_length = $length;	
		}
	
		foreach my $max_length_threshold (50, 100, 200, 500, 1000) {
		
			if ($max_length > $max_length_threshold) {
			
				push $product_ref->{quality_tags}, "ingredients-ingredient-tag-length-greater-than-" . $max_length_threshold;
			
			}
		}
	}
	
	
	if (defined $product_ref->{languages_codes}) {
	
		foreach my $display_lc (keys %{$product_ref->{languages_codes}}) {
		
			my $ingredients_text_lc = "ingredients_text_" . ${display_lc};
			
			if (defined $product_ref->{$ingredients_text_lc}) {
			
				#print STDERR "quality:" .  $product_ref->{$ingredients_text_lc} . "\n";
			
				if ($product_ref->{$ingredients_text_lc} =~ /,(\s*)$/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-ending-comma";
				}
				
				if ($product_ref->{$ingredients_text_lc} =~ /[aeiouy]{5}/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-5-vowels";
				}
				
				if ($product_ref->{$ingredients_text_lc} =~ /[bcdfghjklmnpqrstvwxz]{4}/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-4-consonants";
				}				

				if ($product_ref->{$ingredients_text_lc} =~ /(.)\1{4,}/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-4-repeated-chars";
				}	

				if ($product_ref->{$ingredients_text_lc} =~ /[\$\€\£\¥\₩]/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-unexpected-chars-currencies";
				}		

				if ($product_ref->{$ingredients_text_lc} =~ /[\@]/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-unexpected-chars-arobase";
				}

				if ($product_ref->{$ingredients_text_lc} =~ /[\!]/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-unexpected-chars-exclamation-mark";
				}					
				
				if ($product_ref->{$ingredients_text_lc} =~ /[\?]/is) {
			
					push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-unexpected-chars-question-mark";
				}					
				
				
				# French specific
				#if ($display_lc eq 'fr') {
				
					if ($product_ref->{$ingredients_text_lc} =~ /kcal|glucides|(dont sucres)|(dont acides gras)|(valeurs nutri)/is) {
			
						push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-includes-fr-nutrition-facts";
					}			

					if ($product_ref->{$ingredients_text_lc} =~ /(à conserver)|(conditions de )|(à consommer )|(plus d'info)|consigne/is) {
			
						push $product_ref->{quality_tags}, "ingredients-" . $display_lc . "-includes-fr-instructions";
					}					
				#}
			}
		
		}
	
	}	

}


sub check_quantity($) {
 
	my $product_ref = shift;
	
	# quantity contains "e" - might be an indicator that the user might have wanted to use "℮" \N{U+212E}
	if ((defined $product_ref->{quantity})
		and ($product_ref->{quantity} =~ /(?:.*e$)|(?:[0-9]+\s*[kmc]?[gl]?\s*e)/i)
		and (not ($product_ref->{quantity} =~ /\N{U+212E}/i))) {
		push $product_ref->{quality_tags}, "quantity-contains-e";
	}

}

sub check_bugs($) {

	my $product_ref = shift;
	
	check_bug_code_missing($product_ref);
	check_bug_created_t_missing($product_ref);

}

sub check_bug_code_missing($) {

	my $product_ref = shift;
	
	# https://github.com/openfoodfacts/openfoodfacts-server/issues/185#issuecomment-364653043
	if ((not (defined $product_ref->{code}))) {
		push $product_ref->{quality_tags}, "code-missing";
	}
	elsif ($product_ref->{code} eq '') {
		push $product_ref->{quality_tags}, "code-empty";
	}
	elsif ($product_ref->{code} == 0) {
		push $product_ref->{quality_tags}, "code-zero";
	}

}

sub check_bug_created_t_missing($) {

	my $product_ref = shift;
	
	# https://github.com/openfoodfacts/openfoodfacts-server/issues/185
	if ((not (defined $product_ref->{created_t}))) {
		push $product_ref->{quality_tags}, "created-missing";
	}
	elsif ($product_ref->{created_t} == 0) {
		push $product_ref->{quality_tags}, "created-zero";
	}

}


# Run site specific quality checks

sub check_quality($) {

	my $product_ref = shift;

	$product_ref->{quality_tags} = [];
	
	check_ingredients($product_ref);
	
	check_quantity($product_ref);
	check_bugs($product_ref);	
	
	detect_categories($product_ref);
}





1;
