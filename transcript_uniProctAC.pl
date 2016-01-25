#!/usr/bin/perl -w
use strict;

#written by erin crowgey
#this script is for annotating a vcf file with uniprot accession numbers 

##### input files ##############################################################
my $input_vcf = $ARGV[0]; #vcf input
my $input = "transcripts.txt"; #transcript mapped to AC - Uniprot dowload
open(IN1, $input_vcf) or die "Cannot open the vcf file\n";
open(IN2, $input) or die "Cannot open the uniprot file\n";
################################################################################

###### output files ############################################################
my $output_annotated = $ARGV[0]."\-uniprotAC.vcf";
open(OUT, ">$output_annotated") or die "Cannot open the output annotated file\n";
################################################################################

my %transcripts;
<IN2>;

while (<IN2>){
    chomp $_;
    my $line = $_;
    
    my @array = split(/\t/, $line);
    my $trans = $array[0];
    my $uniprot_ac = $array[1];
    
    $transcripts{$trans} = $uniprot_ac;

}#closes the while loop

################################################################################

############## open up the vcf file that needs annotated #######################


while (<IN1>){
    chomp $_;
    my $line = $_;
    my $value;
    my $ac = "UniProt_AC\=NONE";
    
    if ($line =~ m/^\#/){
        print OUT "$line\n";
    }
    if ($line =~ m/^chr/){
        my @array = split(/\t/, $line);
        my $control = "no";
        my $info = $array[7];
        my @data = split(/\;/, $info);
    
        my $length = @data; 
    
        foreach (my $i = 0; $i < $length; $i++){
            if ($data[$i] =~ m/^SNPEFF_TRANSCRIPT_ID\=(.*)/){
                    $value = $1;
                    
                    if (exists $transcripts{$value}){
                        $ac = "UniProt_AC\=".$transcripts{$value};
                        $control = "yes";
                    }
            
                    else {$ac = "UniProt_AC\=NONE";
                        $control = "yes";} #this is the non-annotated file
            }
        
        
        }#closes the for loop
        my $length_array = @array;
        foreach (my $i = 0; $i < $length_array; $i++){
            if ($i== 7){
            print OUT "$array[7]\;$ac\t";
            }
            else {print OUT "$array[$i]\t";}
        }#closes foreach loop
        print OUT "\n";
    
    }
}#closes while loop


################################################################################

print "end of script!!\n";
die;
