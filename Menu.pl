#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect("DBI:Pg:dbname=eragueneau;host=dbserver", "eragueneau", "motdepasse", { RaiseError => 0 });
print "Menu\n";

print "1. Ajouter_prot\n";
print "2. Modifier_séquence\n";
print "3. Afficher_nom_protéines\n";
print "4. Afficher_nom_gènes\n";
print "5. Afficher_prot_selon_Usr\n";
print "6. Afficher_caractéristiques_protéines\n";

while (my $action = <>) {
    if ($action == 1) {
        #print ("Nom de la protéine ")
        my $entry = <>;
        my $name = <>;
        my $sequence = <>;
        my $longueur = length($sequence);
        $dbh->do("INSERT INTO Proteins VALUES ($entry, $name, $sequence, $length);")


    }
    if ($action==2){
        print"entrz ID du gene cible\n";
        my $entry = <>;
        #my $name = <>;
        print"seq_alt\n";
        my $sequence_alt=<>;
        my $longueur = length($sequence_alt);}

        $dbh->do("UPDATE Proteins SET sequence = $sequence_alt, length = $longueur where entry = $entry;");

    if ($action==3){



    }
    }


