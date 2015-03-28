#!/usr/bin/perl
use LWP::UserAgent;
#Module qui se connecte à la base de donnée QuickGO

#Connexion à la base de données QuickGO
#en utilisant le module LWP::UserAgent
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient: l'Id GO, Sa catégorie (Function, Process ou Component) et la description du GO pour chaque id Gene
sub get_GO_info{

my ($dataset,$gene_id)=@_;
my %dataset=%$dataset;
my @gene_id=@$gene_id;
my @Ac_Id;
my @Gene_Id;
#Pour chaque élément la liste @gene_id (qui contient l'id des genes)
foreach my$main_id(@gene_id){
	#On enregistre l'identifiant uniprot de l'id contenu dans dataset dans une variable
	my $accession_uniprot=$dataset{$main_id."_Uni_ID"};
	#On créé une liste contenant les id uniprot afin de les placer dans l'url et de les séparer par une virgule
	push(@Ac_Id, $accession_uniprot);
	push(@Gene_Id, $main_id);
}
my $ua = LWP::UserAgent->new;
#On effectue une requête http pour se connecter QuickGO et récupérer les différentes informations sur les GO en utilisant les Id Uniprot
my $req = HTTP::Request->new(GET => 'http://www.ebi.ac.uk/QuickGO/GAnnotation?protein='.join(",", @Ac_Id).'&format=tsv&col=proteinID,proteinSymbol,evidence,goID,goName,aspect,ref,with,from');
#On enregistre les informations dans un fichier .tsv (fichier tabulé) pour le parcourir par la suite
my $res = $ua->request($req, "annotation.tsv");
#On ouvre le fichier annotation.tsv
	open (FILE, 'annotation.tsv');
	my $head = <FILE>;
	#On parcours le fichier
	while (<FILE>) {
	    chomp;
	    #Pour chaque id gene on récupère les informations que l'on souhaite sur les GO
	    foreach my$main_id(@gene_id){
		    my ($proteinID, $proteinSymbol, $evidence, $goID, $goName, $aspect, $ref, $with, $from) = split(/\t/);
		    next unless ($dataset{$main_id."_Uni_ID"} eq $proteinID);
		    #On récupère les id GO
		    $dataset{$main_id.'_GO_ID'}{$goID}="";
		    #On récupère la catégorie du GO
		    $dataset{$main_id.'_GO_info_'.$goID}{'categorie'}=$aspect;
		    #On récupère sa description
		    $dataset{$main_id.'_GO_info_'.$goID}{'Go_Name'}=$goName;
		}
	}
	close FILE;
	#On supprime le fichier
	unlink 'annotation.tsv';
	return(%dataset);
}
return 1;