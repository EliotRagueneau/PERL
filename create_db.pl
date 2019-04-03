#!/usr/bin/perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect("DBI:Pg:dbname=eragueneau;host=dbserver", "eragueneau", "motdepasse", { RaiseError => 0 });

$dbh->do("DROP TABLE Reactions;");
$dbh->do("DROP TABLE Genes;");
$dbh->do("DROP TABLE Metadata;");
$dbh->do("DROP TABLE Proteins;");

$dbh->do("CREATE TABLE Proteins(
    Entry VARCHAR(10) CONSTRAINT clef_proteines PRIMARY KEY,
    Names VARCHAR(800),
    Sequence VARCHAR(100000) CONSTRAINT sequence_error CHECK(Sequence SIMILAR TO '[A-IK-NP-TV-Z]*'),
    Length INT CONSTRAINT positive_length CHECK(Length>0)
);");

$dbh->do("CREATE TABLE Reactions(
    Entry VARCHAR(10) CONSTRAINT clef_reactions PRIMARY KEY REFERENCES Proteins(Entry),
    Transcript_ID VARCHAR(20) CONSTRAINT error_transcript CHECK(Transcript_ID SIMILAR TO 'AT[0-9]G[0-9]+.[0-9]'),
    Plant_Reaction VARCHAR(20) CONSTRAINT error_reaction CHECK(Plant_Reaction SIMILAR TO 'R-ATH-[0-9]+' OR NULL)
);");

$dbh->do("CREATE TABLE Genes(
    Entry VARCHAR(10) CONSTRAINT clef_genes PRIMARY KEY REFERENCES Proteins(Entry),
    Names VARCHAR(1000),
    Ontology VARCHAR(10000) CONSTRAINT need_go_id CHECK(Ontology SIMILAR TO 'GO:[0-9]+' OR NULL),
    Synonyme VARCHAR(1000)
);");

$dbh->do("CREATE TABLE Metadata(
    Entry VARCHAR(10) CONSTRAINT clef_meta PRIMARY KEY REFERENCES Proteins(Entry),
    Status VARCHAR(20) CONSTRAINT reviewed_unreviewed CHECK(Status in ('reviewed','unreviewed')),
    Organism VARCHAR(100) CONSTRAINT arath_only CHECK(Organism='Arabidopsis thaliana (Mouse-ear cress)'),
    Entry_names VARCHAR(50) CONSTRAINT arath_end CHECK(Entry_names SIMILAR TO '[A-Z0-9]+_ARATH')
);");

open(UNIPROT, "uniprot-arabidopsisthalianaSequence.tab") || die "can't open uniprot_data";

my $protein_insert = $dbh->prepare("INSERT INTO proteins VALUES (?, ?, ?, ?)");
my $gene_insert = $dbh->prepare("INSERT INTO genes VALUES (?, ?, ?, ?)");
my $meta_data_insert = $dbh->prepare("INSERT INTO metadata VALUES (?, ?, ?, ?)");

<UNIPROT>;
while (<UNIPROT>) {
    chomp;
    my @tab = split(/\t/, $_);
    if ($tab[5] eq "Arabidopsis thaliana (Mouse-ear cress)") {
        $protein_insert->execute($tab[0], $tab[3], $tab[10], $tab[6]);
        if ($tab[4] eq "") {
            $tab[4] = undef;
        }
        $gene_insert->execute($tab[0], $tab[4], $tab[8], $tab[7]);
        $meta_data_insert->execute($tab[0], $tab[2], $tab[5], $tab[1]);
    }
}
close(UNIPROT);

open(ENSEMBL, "mart_export.csv") || die "can't open EnsemblPlants data";

my $reactoins_insert = $dbh->prepare("INSERT INTO reactions VALUES (?,?,?)");

<ENSEMBL>;
while (<ENSEMBL>) {
    chomp;
    my @tab = split(/,/, $_);
    $reactoins_insert->execute($tab[2], $tab[1], $tab[3])
}
close(ENSEMBL)
