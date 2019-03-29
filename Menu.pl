#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect("DBI:Pg:dbname=eragueneau;host=dbserver", "eragueneau", "motdepasse", { RaiseError => 0 });
print "Menu\n";

print "1. Ajouter prot\n";
print "2. Modifier séquence\n";
print "3. Afficher nom protéines\n";
print "4. Afficher nom gènes\n";
print "5. Afficher prot selon Usr\n";
print "6. Afficher caractéristiques protéines\n";

my $action = <STDIN>;
while ($action != 0) {
    if ($action == 1) {
        print("Entrée de la protéine (code Uniprot) ?\n");
        my $entry = <STDIN>;
        chomp $entry;
        print("Nom de la protéine ?\n");
        my $name = <STDIN>;
        chomp $name;
        print("Séquence de la protéine ?\n");
        my $sequence = <STDIN>;
        chomp $sequence;
        $sequence = uc $sequence;
        while ($sequence =~ /[^AC-NP-TVWY]/) {
            print("Séquence de la protéine invalide, veuillez la modifier.\n");
            $sequence = <STDIN>;
            chomp $sequence;
            $sequence = uc $sequence;
        }
        my $longueur = length($sequence);
        my $add_prot = $dbh->prepare("INSERT INTO Proteins VALUES (?, ?, ?, ?);");
        $add_prot->execute($entry, $name, $sequence, $longueur);
        print("$entry, $name, $sequence, $longueur \n");
    }
    if ($action == 2) {
        print "Entrez l'entrée de la protéine à modifier.\n";
        my $entry = <STDIN>;
        chomp $entry;
        print "Quelle est la nouvelle séquence ?\n";
        my $sequence_alt = <STDIN>;
        chomp $sequence_alt;
        $sequence_alt = uc $sequence_alt;
        while ($sequence_alt =~ /[^AC-NP-TVWY]/) {
            print("Séquence invalide, veuillez la modifier.\n");
            $sequence_alt = <STDIN>;
            chomp $sequence_alt;
            $sequence_alt = uc $sequence_alt;
        }

        my $longueur = length($sequence_alt);

        my $mod_seq = $dbh->prepare("UPDATE Proteins SET sequence = ?, length = ? where entry = ?;");

        $mod_seq->execute($sequence_alt, $longueur, $entry);

    }

    if ($action == 3) {
        my $name_prot = $dbh->prepare("select p.entry, names from proteins p join reactions r on p.entry = r.entry;");
        $name_prot->execute();

    }
    print "1. Ajouter une protéine\n";
    print "2. Modifier une séquence protéique\n";
    print "3. Afficher nom protéines\n";
    print "4. Afficher nom gènes\n";
    print "5. Afficher prot selon Usr\n";
    print "6. Afficher caractéristiques protéines\n";
    $action = <STDIN>;

}


