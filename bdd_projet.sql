drop table Reactions;
drop table Genes;
drop table Metadata;
drop table Proteins;

create table Proteins(
    Entry varchar(10) constraint clef_proteines primary key,
    Names varchar(400),
    Sequence varchar(100000) constraint sequence_error check(Sequence LIKE '[ACDEFGHIKLMNPQRSTVWY]%'),
    Length int constraint positive_length check(Length>0)
);

create table Reactions(
    Entry varchar(10) constraint clef_reactions primary key references Proteins(Entry),
    Transcript_ID varchar(20) constraint error_transcript check(Transcript_ID LIKE 'AT[0123456789]G[0123456789]%.[0123456789]'),
    Plant_Reaction varchar(20) constraint error_reaction check(Plant_Reaction LIKE 'R-ATH-[0123456789]%' or null)
);

create table Genes(
    Entry varchar(10) constraint clef_genes primary key references Proteins(Entry),
    Names varchar(1000),
    Ontology varchar(1000) constraint need_go_id check(Ontology LIKE '.%[[]GO:[0123456789]%[]].%' or null),
    Synonyme varchar(1000)

);

create table Metadata(
    Entry varchar(10) constraint clef_meta primary key references Proteins(Entry),
    Status varchar(20) constraint reviewed_unreviewed check(Status in ('reviewed','unreviewed')),
    Organism varchar(50) constraint arath_only check(Organism='Arabidopsis thaliana (Mouse-ear cress)'),
    Entry_names varchar(50) constraint arath_end check(Entry_names LIKE '.%[_]ARATH')
);
