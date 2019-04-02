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
    open(my $fh, '>', $file_name) || die "can't open file";
    print $fh "<!DOCTYPE html>\n<head>\n<link rel='stylesheet' href='../styles.css'>\n</head>\n<body>\n";
    print $fh "<h1>$title</h1>\n";
    print $fh "<table>\n\t<thead>\n\t\t<tr>\n\t\t\t<th>";
    print $fh join("</th>\n\t\t\t<th>", @column_names);
    print $fh "</th>\n\t\t</tr>\n\t</thead>\n\t<tbody>\n";
    while (my @t = $executed_querry->fetchrow_array()) {
        for (@t) {$_ = 'N.A.' if !defined($_);}
        print $fh "\t\t<tr>\n\t\t\t<td>";
        print $fh join("</td>\n\t\t\t<td>", @t);
        print $fh "</td>\n\t\t</tr>\n";
    }
    print $fh "\t</tbody>\n</table>\n</body>";
    close($fh);
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
    }

    if ($action == 2) {
        print "Entrez l'entrée de la protéine à modifier.\n";
        my $entry = <STDIN>;
        chomp $entry;

        print "Quelle est la nouvelle séquence ?\n";
        my $sequence = get_sequence();

        my $longueur = length($sequence);

        my $mod_seq = $dbh->prepare("UPDATE Proteins SET sequence = ?, length = ? where entry = ?;");
        my $nb_modified = $mod_seq->execute($sequence, $longueur, $entry);
        if ($nb_modified == 0) {
            print("L'entrée donnée n'éxistant pas dans la base, nous n'avons pas pu modifier sa séquence\n");
        }
    }

    if ($action == 3) {
        my $name_prot = $dbh->prepare("SELECT p.entry, names FROM proteins p JOIN reactions r ON p.entry = r.entry;");
        $name_prot->execute();

        show_results($name_prot);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            $name_prot->execute();
            save($name_prot, "linked_protein_names", "Proteins linked with EnsemblPlants", "Entry", "Protein name");
            print("Résultats sauvegardés\n")
        }
    }

    if ($action == 4) {
        my $name_gene = $dbh->prepare("SELECT g.entry, names FROM genes g JOIN reactions r ON g.entry = r.entry WHERE names IS NOT NULL;");
        $name_gene->execute();

        show_results($name_gene);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            $name_gene->execute();
            save($name_gene, "linked_gene_names", "Genes linked with EnsemblPlants", "Entry", "Gene names");
            print("Résultats sauvegardés\n")
        }
    }

    if ($action == 5) {
        print("Les protéines affichées doivent avoir une taille supérieure à : ");
        my $size = <STDIN>;
        chomp $size;

        my $prot_sup = $dbh->prepare("SELECT entry, names, length FROM proteins WHERE length >= ? ORDER BY length DESC;");
        $prot_sup->execute($size);

        show_results($prot_sup);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            $prot_sup->execute();
            my $name = "prot_sup_" . $size;
            my $title = "Protein of length greater than " . $size;
            save($prot_sup, $name, $title, "Entry", "Protein names", "Protein Length");
            print("Résultats sauvegardés\n")
        }
    }

    if ($action == 6) {
        print("Quel identifiant d'enzyme E.C. vous intéresse (format : x.x.x.x)?\n");
        my $ec_id = <STDIN>;
        chomp $ec_id;
        while ($ec_id !~ /\d+\.\d+\.\d+\.\d+/) {
            print "Format ( x.x.x.x ) non respecté, veuillez réessayer \n";
            $ec_id = <STDIN>;
            chomp $ec_id;
        }

        my $ec = "%EC " . $ec_id . "%";

        my $ec_car = $dbh->prepare("
        SELECT p.entry, m.entry_names, m.status ,p.names, p.sequence, p.length, r.transcript_id, r.plant_reaction
        FROM proteins p
            JOIN reactions r ON p.entry = r.entry
            JOIN metadata m ON p.entry = m.entry
        WHERE p.names LIKE ?;");

        if ($ec_car->execute($ec) == 0) {
            $ec_car = $dbh->prepare("
        SELECT p.entry, m.entry_names, m.status ,p.names, p.sequence, p.length
        FROM proteins p
            JOIN metadata m ON p.entry = m.entry
        WHERE p.names LIKE ?;");
            $ec_car->execute($ec)
        }

        show_results($ec_car);

        my $answer = save_yes_no();
        if ($answer eq "O") {
            $ec_car->execute();
            my $name = "carac_EC_" . $ec_id;
            my $title = "Characteristics of enzyme EC " . $ec_id;
            save($ec_car, $name, $title, "Entry", "Entry name", "Status", "Protein names", "Protein Sequence", "Protein Length", "Transcript ID", "Plant Reaction");
            print("Résultats sauvegardés\n")
        }
    }

    menu;
    $action = <STDIN>;
}


