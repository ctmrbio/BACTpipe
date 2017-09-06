#!/usr/bin/perl

use strict ;
use warnings ;

## Aim: Make a script that cleans up de novo assembly output multifasta and filters away low coverage and short scaffolds
## For questions, please contact kaisa.thorell@ki.se

my $fastafile ;
my $prefix ;

if ($#ARGV == 1)	{					#First check that the program has received the correct number of arguments
	$fastafile	= $ARGV[0] ;
	$prefix = $ARGV[1] ;
	print 	"\n\nRunning FilterAssembly.pl on $ARGV[0].\n\n"
			."Output prefix will be $prefix.\n\n"  ; 

}	else {								#Otherwise die explaining the usage of the script
		die "\nUsage: FilterAssembly.pl <scaffolds.fasta>, <output_prefix>\n"
			."Please provide the correct number of arguments\n\n" ;	
	}
	
open (my $SCAFFOLDS, "<", $fastafile );
open OUT, ">$prefix\_covfiltered.fasta" ;


## Convert the multifasta file so that each sequence is one one row

my @onelinefasta = &Fasta1line($SCAFFOLDS) ;

## Sort the fasta file on descending scaffold length

my @sortedfasta = &Length_sort(@onelinefasta) ;

##Filter out the scaffolds having less than half the coverage of that of the scaffold out of the top 10 longest that has the lowest coverage :)
##Filter out scaffolds shorter than $length_cutoff

my @covfiltered = &Covfilter(@sortedfasta, 500) ;



##Output the filtered assembly

print "\nThe filtered sequences can be found in $prefix\_covfiltered.fasta\n\n" ;

foreach (@covfiltered)	{
	print OUT "$_\n" ;
}

close OUT ;




sub Fasta1line	{

# Subroutine adapted from Fasta1line.pl, author Joseph Fass
# http://bioinformatics.ucdavis.edu

	my $usage =	"\n\&Fasta1line processes a multifasta file so that each sequence is concatenated to one line following the header.\n".
				"\nUsage: \&Fasta1line (\$infasta)\n\n".
  	          	"\n";
  	my $infasta ;
  	my @oneline_fasta ;
	
	## If the input argument is submitted, continue, else die.
	if ($#_ == 0)	{
		$infasta = shift(@_) ;
		print "Running \&Fasta1line. \nUsage: \&Fasta1line (\$infasta)\n\n" ;
		
	}	else {
			die $usage ;
		}
	
	my $sequence ;
	my $linecount = 1 ;

	while (<$infasta>) {
	
		chomp ;

		if ($linecount == 1)	{
			unless (m/^>NODE\_[0-9]/)	{
				die "The input file does not have the right format. Please provide a de novo assembly scaffold or contig fasta file.\n\n" ;
			}
		}
		
		if (m/^>/) { 							# If the line is a header line
			if ($linecount == 1)	{			# If this is the first header line, 
				push (@oneline_fasta, $_) ;		# just add the header to the oneline_fasta array
				$linecount++;					# Increase the linecount
			}	else	{
					push (@oneline_fasta, $sequence); # print the concatenated sequence to output
					push (@oneline_fasta, $_) ;	# print the new header to oneline_fasta
					$sequence = '' ;			# empty the sequence string
				}
		}	else	{ 							# not a header line? - must be sequence
    			chomp ; 						# remove newline at end
    			$sequence .= $_; 				# append additional sequence
			}
	}
	
	push (@oneline_fasta, $sequence);			# print the last sequence to the file
	
	return @oneline_fasta ;
}



sub Length_sort	{

##Length_sort sorts a multifasta with one sequence line per fasta entry on sequence length

	my $usage =	"\n\&Length_sort sorts a multifasta with one sequence line per fasta entry on sequence length.\n".
            	"Usage: \&Length_sort (\@onelinefasta)\n\n";
	
	my @oneline_fasta ;
	my $sorted_fasta ;

	## If the input argument is submitted, continue, else die
	
	if (@_)	{
		@oneline_fasta = @_ ;
		print "Running \&Length_sort. \nUsage: \&Length_sort (\@onelinefasta)\n\n" ;
		
	}	else {
		die $usage ;
		}

	my $header ;
	my $seq ;
	my %seqs ;
	my @headers_sorted ;
	my @sorted_seqs ;
	
	while (1)	{
		last unless (@oneline_fasta) ;
		$header = shift (@oneline_fasta) ;				# Assign that line "header"
		$seq = shift (@oneline_fasta) ;					# $seq will be the next line of the fasta file (the sequence string)
		$seqs{$header} = $seq ;							# $seq will be the value of key $header in the %seqs hash
	} 

	@headers_sorted = (reverse sort {length($seqs{$a}) <=> length($seqs{$b})} keys %seqs) ; #Sort the headers in correct order 
	
	foreach (@headers_sorted) {				
		push (@sorted_seqs, $_ ) ;
		push (@sorted_seqs, $seqs{$_}) ;				# Retrieve the sequence for each header from %seqs into an array
	}	
	
		
	return @sorted_seqs ;
	

}


sub Covfilter	{

	##This sub filters out contigs with too low coverage and to short length

	my $usage =	"\n\&Covfilter filters out contigs with too low coverage and to short length.".
			"/nUsage: \&Covfilter (\@sortedfasta, length_cutoff)\n\n";
			
	my @sorted_fasta ;
	my $length_cutoff ;
	my $cov_cutoff ;
	my $keep_fasta ;

	## If there are two arguments submitted, continue, else die.
		if (@_)	{
			$length_cutoff = pop(@_) ;
			@sorted_fasta = @_ ;
			print "Running \&Covfilter with length cutoff $length_cutoff.\n" 
			."Usage: \&Covfilter (\@sortedfasta, length_cutoff)\n\n" ;
		
		}	else {
			die $usage ;
		}
	
	my @header ;
	my $coverage ;
	my @headers ;
	
	my $cov ;
	my @covs ;
	
	my @keep_fasta ;
	my @discard ;
	

	
	foreach (@sorted_fasta)	{
		
		last if ($#headers > 8) ;					# For the first ten header lines	
			if (m/^>/)	{							# If the line is a header line
				push (@headers, $_) ;				# Add it to the array @headers
				#print "The fasta entries are $_ \n";
			}						
	}
		
	
	foreach (@headers)	{							# For each line in @headers
		@header = split(/\_/, $_) ;					# Split the line on "_"
		$cov = $header[5] ;							# The coverage will be found at index 5
		push(@covs, $cov) ;							# Put the coverage in the @covs array
	}


	my $median;
	my $mid = int @covs/2;
	my @sorted_covs = sort { $a <=> $b } @covs;					# Sort the covs array on descending coverage. NB! Use numerical sorting!!!
	
	#foreach (@sorted_covs) {
	#	print "covs are $_\n" ;
	#}
	
	#print "mid is $mid\n";

	if (@covs % 2) {
    	$median = $sorted_covs[$mid];
    	print "The median coverage of the ten longest contigs is $median\n"  ;
    	
	}	else	{
    		$median = ($sorted_covs[$mid-1] + $sorted_covs[$mid])/2;
    		print "The median coverage of the ten longest contigs is $median\n"  ;
		} 
							
	$cov_cutoff = ($median/2) ;						# The cov_cutoff is the half the median coverage value of the 10 longest contigs
	
	print "The coverage cutoff is $cov_cutoff\n" ;
	print "The length cutoff is $length_cutoff\n\n" ;
	
	
	foreach (@sorted_fasta) {
	
		if (m/^>/)	{								# If the line is a header line
			@header = split(/\_/, $_) ;				# Assign that line "header" and split it into columns on "_"
		
#			print "Contig length is $header[3], and coverage is $header[5]\n" ;
		
			if (($header[3] > $length_cutoff) && ($header[5] > $cov_cutoff)) {
#				print "Keep sequence $_ \n\n" ;
				push(@keep_fasta, $_) ;				# Add that line to the $keep fasta
															
			}	else	{
#					print "DISCARD CONTIG\n\n" ;
					push @discard, ($_) ;			# Keep track of the discarded headers
					shift(@sorted_fasta) ;			# Don't add $seq to the $keep fasta
				}
		}	else {
				push(@keep_fasta, $_) ;				# $seq will be the next line of the fasta file (the sequence string)
													# Add $seq to the $keep fasta
			}
	} 
	
	print "Discarded contigs;\n" ;
	
	foreach (@discard)	{
		print "$_\n" ;
	}
	
	return @keep_fasta ;
	
}

