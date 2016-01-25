#!/usr/bin/perl -w
use strict;

#written by erin crowgey
#adds the minor allele global frequency from the dbsnp to the variant data (vcf format)
#input 1 = vcf file
#input 2 = MAF allele
#input 3 = user specifications
#out 1 = original vcf with MAF annotated
#out 2 = vcf file of the variants that meet criteria defined by user
#out 3 = MAF for the variants in the vcf file - can be used to plot distribution - R code

############## input files #####################################################
my $input_var = "file.vcf";
my $input_allele = "ALL.wgs.integrated_phase1_v3.20101123.snps_indels_sv.sites.vcf";
my $user_input = "user_input.txt";

open(IN3, "$user_input") or die "Cannot open the user input file\n";
open(IN2, "$input_var") or die "cannot open the input\n";
open(IN1, "$input_allele") or die "Cannot open the allele input\n";
################################################################################

############ output files ###################################################### 
my $out_put = "common-confidence-BSS-3-5-14.vcf"; #the original vcf annotated with the new information
open(OUT1, ">$out_put") or die "cannot open the output file\n";

my $output_dis = "MAF-variants-3-5-14.txt";
open(OUT2, ">$output_dis") or die "Cannot open the output for the distributions\n"; #MAF for distribution calculations

#################################################################################

################ user specification ############################################
my $limit;
my $individuals;


while (<IN3>){
    chomp $_;
    my $line = $_;
    
    if ($line =~ m/^MAF/){
        my @array = split(/\t/, $line);
        $limit = $array[1] / 100;
    }
    
    if ($line =~ m/^total number of individuals/){
        my @array = split(/\t/, $line);
        $individuals = $array[1];
    }
    
}#closes while loop
close (IN3);


 
################################################################################

################# 1000Genomes File with MAF  ###################################
my %allele;
print "we are starting to read in the MAF\n";

while (<IN1>){
    my $line = $_;
    chomp $line;
    
    if ($line =~ m/\#/){}#do nothing right now
    elsif ($line =~ m/^\d+/ || $line =~ m/^chrX/ || $line =~ m/^chrY/){
    
        my @array = split(/\t/, $line);
        my $var_name = $array[2];
        my @info = split(/\;/, $array[7]);
        my $length = @info;
        
        foreach (my $i = 0; $i < $length; $i++){
            if ($info[$i] =~ m/^AF\=(.*)/){
                $allele{$var_name} = $1;
                $i = $length;
                
            }
        }#closes the for loop
    }#closes if statement
}#closes while loop

print "we are finished reading in the minor allele frequencies\n";
close(IN1);
################################################################################

######### vcf file input #######################################################
print "we are annotating the variants with the MAF\n";
my $counts_yes = 0;
my $counts_no = 0;
my $counts_high = 0;
my $variant_start = 0;
my $rewrite = "no";
my $flip;

while (<IN2>){
    my $line = $_;
    chomp $line;
    my $verdict = '';
    
    if ($line =~ m/^\#\#INFO\=\<ID\=COMMON/){
        $rewrite = "yes";
        print OUT1 "##INFO=<ID=COMMON,Number=1,Type=String,Description=\"The common criteria used was MAF less than XX\">\n";
    }
    
    elsif ($line =~ m/^\#CHR/ && $rewrite eq "no"){
        print OUT1 "##INFO=<ID=COMMON,Number=1,Type=String,Description=\"The common criteria used was MAF less than XX\">\n";
        print OUT1 "$line\n";
    }
    
    elsif ($line =~ m/^\#CHR/ && $rewrite eq "yes"){
        print OUT1 "$line\n";
    }
    
    elsif ($line =~ m/^\#/){print OUT1 "$line\n";}   
    
    elsif ($line =~ m/^chr\d+/ || $line =~ m/^chrX/ || $line =~ m/^chrY/){
        $variant_start ++;
        my @array = split(/\t/, $line);
        my $length = @array;
        if ($array[2] =~ m/^rs/){
            my $rs = $array[2];
            
            if (exists $allele{$rs}){
                $flip = 1 - $allele{$rs};
            }
            else {$flip = 100;}
            
            if (exists $allele{$rs} && $allele{$rs} <= $limit){
                    
                    $verdict = "GLOBAL_MAF\=PASS \= $allele{$rs}";
                    $counts_yes ++;
                    print OUT2 "$allele{$rs}\n";
            }
                        
            elsif (exists $allele{$rs} && $flip <= $limit){
                    $verdict = "GLOBAL_MAF\=PASS_flip \= $allele{$rs}";
                    $counts_yes ++;
                    print OUT2 "$allele{$rs}\n";
            
            }
            
            elsif (exists $allele{$rs} && $allele{$rs} > $limit){
                $verdict = "GLOBAL_MAF\=FAIL \= $allele{$rs}";
                $counts_high ++;
                print OUT2 "$allele{$rs}\n";
            }
            
        else{
                $counts_no ++;
                $verdict = "GLOBAL_MAF\=NA";
            }
        
        }    
        
        else {
            $counts_no ++;
            $verdict = "GLOBAL_MAF\=NA"; #these are variants that do not have an rs number and hence no GLOBAL MAF to annotate
        }
        
        my @info_line = split(/\;/, $array[7]);
        my $lenght_info = @info_line;
        my $rewrite_info = 'no';
        my $new_info = '';
        
        foreach (my $c = 0; $c < $lenght_info; $c ++){
            if ($info_line[$c] =~ m /^GLOBAL_MAF/){
                $rewrite_info = 'yes';
                $new_info .= $verdict . "\;";
            }
            
            else {$new_info .= $info_line[$c] . "\;";}
            
        }
        
        if ($rewrite_info eq 'no'){
            $new_info .= $verdict;
        }
        
        foreach (my $i = 0; $i < $length; $i++){
            if ($i == 7){
                print OUT1 "$new_info\t";
            }
            else {print OUT1 "$array[$i]\t";}
        }
        print OUT1 "\n";
           
    }#closes if statement about chr

}# closes while loop
################################################################################
################################################################################
print "we are done annotating the MAF\n";
print "The number of variants with a MAF < $limit is $counts_yes\n The number of variants without a MAF is $counts_no\n The number of variants with a MAF > $limit is $counts_high\n";
print "The starting number of variants is $variant_start\n";
close(IN2);
close (OUT1);
################################################################################
print "end of script\n";
die;
