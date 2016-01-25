#!/usr/bin/perl -w
use strict;

#written by erin crowgey

#genetic analysis module of the variant analysis pipeline
#input 1 = vcf file
#input 2 = user specification
#output 1 = annotated vcf file
#output 2 = temp vcf file with variants that meet criteria

################# in-put files #################################################
my $vcf = $ARGV[0]; #example-8-8-15.txt";
open (IN1, $vcf) or die "cannot open the vcf file\n";

my $zygous = "recessive"; 
################################################################################

############# output files #####################################################
my $output = "genetic-8-8-15" . $vcf; #annotated vcf file
open(OUT1, ">$output") or die "Cannot open the output file\n";

################################################################################
############# vcf file #########################################################
my $counts_one = 0;
while (<IN1>){
    my $all = '';
    my $line = $_;
    chomp $line;
    my $control = "no";
    
    if ($line =~ m/^\#\#/){print OUT1 "$line\n";}
    
    elsif ($line =~ m/^\#CHR/){
        print OUT1 "##INFO=<ID=GENETIC_RECESSIVE,Number=1,Type=String,Description=\"recessive\">\n";
        print OUT1 "$line\n";
    }
    
    elsif ($line =~ m/^chr\d+/ || $line =~ m/^chrX/ || $line =~ m/^chrY/){
        my @array = split(/\t/, $line);
        my $length_line = @array;
        #11 - proband with 9 and 10 parents
        my $verdict = &genotype($array[11], $array[9], $array[10]);
        if ($verdict eq "yes"){
            $counts_one ++;
            $all = "003";
            $control = "yes";
        }

        elsif ($verdict eq "nd_yes"){
            $counts_one ++;
            $all = "nd_003";
            $control = "yes";
        }
           
        foreach (my $i = 0; $i < $length_line; $i++){
            if ($i == 7){
                if ($all =~ m/\d+/){
                    print OUT1 "$array[$i]\;GENETIC_RECESSIVE=recessive\t";
                }
                elsif ($all =~m /^nd/){
                    print OUT1 "$array[$i]\;GENETIC_RECESSIVE=recessive_nd\t";
                }
                else {print OUT1 "$array[$i]\;GENETIC_RECESSIVE=NONE\t";}
            }
            else{print OUT1 "$array[$i]\t";}
        }
            
        print OUT1 "$all\t\n";
    }
}#closes while loop

print "The total number of recessive variants for family $counts_one\n";
print "end of script\n";
die;
################################################################################

#### sub rountines #############################################################
#################################################################################
sub genotype{
    my $genotype_proband = $_[0];
    my $genotype_one = $_[1];
    my $genotype_two = $_[2];
    my $parent_one = 0;
    my $parent_two = 0;
    
    if ($genotype_proband =~ m/^\./)
        {return "no";}# do nothing because there is no data
    
    else {
        $genotype_proband =~ m/(\d)\/(\d)/;
        if ($1 > 0 && $2 > 0){
            if ($genotype_one =~ m/^\./){
                $parent_one = 1;
                if ($genotype_two =~ m/^\./){$parent_two = 1;
                    return "nd_yes";
                }
                else {$genotype_two =~ m/(\d)\/(\d)/;
                    if ($1 == 0 || $2 == 0){
                        return "yes";
                    }
                        else {return "no";}
                    }            
            }
            else {$genotype_one =~ m/(\d)\/(\d)/;
                if ($1 == 0 || $2 == 0){
                    if ($genotype_two =~ m/^\./){$parent_two = 1;
                        return "nd_yes";
                    }
                    else {$genotype_two =~ m/(\d)\/(\d)/;
                        if ($1 == 0 || $2 == 0){
                            return "yes";
                        }
                        else {return "no";}
                    }
                }
        
            }
            
            
    
            if ($parent_one == 1 && $parent_two == 1){
                return "nd_yes";
            }
        
        }
    }
}
#################################################################################
