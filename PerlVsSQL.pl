#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

print("Quelle est la longueur minimale des protéines que vous désirez afficher ?\n");
my $min_len = <STDIN>;
my %hash;

open(my $file, "uniprot-arabidopsisthalianaSequence.tab") || die "can't open uniprot_data";
<$file>;
while (my $line = <$file>) {
    chomp $line;
    my @entry = split(/\t/, $line);
    if ($entry[6] > $min_len && $entry[5] eq "Arabidopsis thaliana (Mouse-ear cress)") {
        $hash{$entry[0]} = \@entry;
    }
}
close($file);

open($file, "mart_export.csv") || die "can't open EnsemblPlants data";
<$file>;
while (my $line = <$file>) {
    chomp $line;
    my @entry = split(/,/, $line);
    if (defined $entry[2]) {
        if (exists($hash{$entry[2]})) {
            my $arrayToInsert = $hash{$entry[2]};
            push(@{$arrayToInsert}, $entry[0]);
            push(@{$arrayToInsert}, $entry[1]);
            if (defined $entry[3]) {
                push(@{$arrayToInsert}, $entry[3]);
            }
        }
    }
}
close($file);

for (values(%hash)) {
    print join(" | ", @$_), "\n\n";
}
