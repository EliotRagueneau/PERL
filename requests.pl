#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect("DBI:Pg:dbname=eragueneau;host=dbserver", "eragueneau", "motdepasse", { RaiseError => 0 });

sub menu {
    print "\n\n\tMenu\n";
    print ">1 Ajouter une protéine\n";
    print ">2 Modifier une séquence protéique\n";
    print ">3 Afficher le nom des protéines (identifiant UniProt) qui sont référencées dans la table issue de EnsemblPlant\n";
    print ">4 Afficher le nom des gènes du fichier UniProt qui sont également référencés dans le fichier EnsemblPlant\n";
    print ">5 Afficher les protéines d'une taille supérieure à ...\n";
    print ">6 Afficher les caractéristiques dune protéine selon son identifiant E.C.\n";
    print ">0 Quitter\n";
}

sub get_sequence {
    my $sequence = <STDIN>;
    chomp $sequence;
    $sequence = uc $sequence;
    if ($sequence =~ /[^A-IK-NP-TV-Z]/) {
        print("Séquence protéique invalide, veuillez la modifier.\n");
        $sequence = get_sequence();
    }
    return $sequence;
}

sub save_yes_no {
    print "Voulez vous sauvegarder les résultats [O|N]\n";
    my $answer = <STDIN>;
    chomp $answer;
    return uc $answer;
}

sub show_results {
    my $executed_querry = shift;
    while (my @t = $executed_querry->fetchrow_array()) {
        print join(" | ", @t), "\n"
    }
}

sub save {
    my $executed_querry = shift;
    my $file_name = shift;
    my $title = shift;
    my @column_names = @_;
    $file_name = "Saves/" . $file_name . ".html";
    $executed_querry->execute();
    open(my $fh, '>', $file_name) || die "can't open file";
    print $fh "<!DOCTYPE html>\n<head>\n\t<link rel='stylesheet' href='../styles.css'>\n</head>\n<body>\n";
    print $fh "\t<h1>$title</h1>\n";
    print $fh "\t<table>\n\t\t<thead>\n\t\t\t<tr>\n\t\t\t\t<th>";
    print $fh join("</th>\n\t\t\t\t<th>", @column_names);
    print $fh "</th>\n\t\t\t</tr>\n\t\t</thead>\n\t\t<tbody>\n";
    while (my @t = $executed_querry->fetchrow_array()) {
        for (@t) {$_ = 'N.A.' if !defined($_);}
        print $fh "\t\t\t<tr>\n\t\t\t\t<td>";
        print $fh join("</td>\n\t\t\t\t<td>", @t);
        print $fh "</td>\n\t\t\t</tr>\n";
    }
    print $fh "\t\t</tbody>\n\t</table>\n</body>";
    close($fh);
    print("Résultats sauvegardés\n")
}

menu;
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
        my $sequence = get_sequence();

        my $longueur = length($sequence);

        my $add_prot = $dbh->prepare("INSERT INTO Proteins VALUES (?, ?, ?, ?);");
        $add_prot->execute($entry, $name, $sequence, $longueur);

        print("$entry, $name, $sequence, $longueur \n");
        $add_prot->finish();
    }

    if ($action == 2) {
        print "Entrez l'entrée de la protéine à modifier.\n";
        my $entry = <STDIN>;
        chomp $entry;

        print "Quelle est la nouvelle séquence ?\n";
        my $sequence = get_sequence();

        my $longueur = length($sequence);

        my $mod_seq = $dbh->prepare("UPDATE Proteins SET sequence = ?, length = ? where entry = ?;");

        if ($mod_seq->execute($sequence, $longueur, $entry) == 0) {
            print("L'entrée donnée n'éxistant pas dans la base, nous n'avons pas pu modifier sa séquence\n");
        }
        $mod_seq->finish();
    }

    if ($action == 3) {
        my $name_prot = $dbh->prepare("SELECT p.entry, names FROM proteins p JOIN reactions r ON p.entry = r.entry;");
        $name_prot->execute();

        show_results($name_prot);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            save($name_prot, "linked_protein_names", "Proteins linked with EnsemblPlants", "Entry", "Protein name");
        }
        $name_prot->finish();
    }

    if ($action == 4) {
        my $name_gene = $dbh->prepare("SELECT g.entry, names FROM genes g JOIN reactions r ON g.entry = r.entry WHERE names IS NOT NULL;");
        $name_gene->execute();

        show_results($name_gene);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            save($name_gene, "linked_gene_names", "Genes linked with EnsemblPlants", "Entry", "Gene names");
        }
        $name_gene->finish();
    }

    if ($action == 5) {
        print("Les protéines affichées doivent avoir une taille supérieure à : ");
        my $size = <STDIN>;
        chomp $size;

        my $prot_sup = $dbh->prepare("
        SELECT DISTINCT m.entry, m.entry_names, m.status, p.names, p.length, g.names, g.ontology, g.synonyme, r.transcript_id, r.plant_reaction, p.sequence
        FROM proteins p
            JOIN genes g ON p.entry = g.entry
            JOIN metadata m ON p.entry = m.entry
            LEFT OUTER JOIN reactions r on p.entry = r.entry
        WHERE p.length > ?;");

        $prot_sup->execute($size);

        show_results($prot_sup);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            my $name = "prot_sup_" . $size;
            my $title = "Protein of length greater than " . $size;
            save($prot_sup, $name, $title, "Entry", "Entry name", "Status", "Protein names", "Protein Length", "Gene names", "Gene Ontology", "Gene Names synonyms","Transcript ID", "Plant Reaction", "Protein Sequence");
        }
        $prot_sup->finish();

    }

    if ($action == 6) {
        print("Quel identifiant d'enzyme E.C. vous intéresse (format : x.x.x.x)?\n");
        my $ec_id = <STDIN>;
        chomp $ec_id;
        while ($ec_id !~ /\d\.\d{1,2}\.\d{1,2}\.\d{1,4}/) {
            print "Format ( x.x.x.x ) non respecté, veuillez réessayer \n";
            $ec_id = <STDIN>;
            chomp $ec_id;
        }

        my $ec = "%EC " . $ec_id . "%";

        my $ec_car = $dbh->prepare("
        SELECT DISTINCT m.entry, m.entry_names, m.status, p.names, p.length, g.names, g.ontology, g.synonyme, r.transcript_id, r.plant_reaction, p.sequence
        FROM proteins p
            JOIN genes g ON p.entry = g.entry
            JOIN metadata m ON p.entry = m.entry
            LEFT OUTER JOIN reactions r on p.entry = r.entry
        WHERE p.names SIMILAR TO ?;");

        $ec_car->execute($ec);

        show_results($ec_car);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            my $name = "carac_EC_" . $ec_id;
            my $title = "Characteristics of enzyme EC " . $ec_id;
            save($ec_car, $name, $title, "Entry", "Entry name", "Status", "Protein names", "Protein Length", "Gene names", "Gene Ontology", "Gene Names synonyms","Transcript ID", "Plant Reaction", "Protein Sequence");
        }
        $ec_car->finish();
    }

    menu;
    $action = <STDIN>;
}

$dbh->disconnect();


