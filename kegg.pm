#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
#Module qui se connecte à la base de donnée Kegg

#Connexion à la base de données Kegg
#en utilisant le module LWP::UserAgent
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient tous les ids uniprot correspondant au gène

sub get_kegg_info{
my ($dataset,$gene_id)=@_;
my%dataset=%$dataset;
my@gene_id=@$gene_id;
#On parcours chaque id de la liste ....
foreach my$main_id(@gene_id){
	#On part de l'id Uniprot
	my $accession_uniprot=$dataset{$main_id."_Uni_ID"};
	my $agent = LWP::UserAgent->new(agent => "libwww-perl");
	#On effectue une requête http (conv =conversion) conv va nous permettre d'accéder à l'id kegg apartir de l'id Uniprot
	my $response = $agent->get("http://rest.kegg.jp/conv/genes/uniprot:$accession_uniprot");
	my $rep=$response->content or die 'error' . $response->status_line ."\n";
	chomp $rep;
	#On obtient des données tabulés, on va donc définir que chaque élément séparé par une tabulation sera un élément de la liste
	my @id_Kegg=split("\t",$rep);
	#On séléctionne le deuxième élément de la liste qui correspond à l'id kegg spécifique d'un gène
	my $id_KEGG=$id_Kegg[1];
	$dataset{$main_id.'_KEGG_ID'}=$id_KEGG;
	#On va ensuite se connecter à une url pour obtenir les id Kegg des voies métabolliques spécifique à l'id kegg du gène	
	my$response1 = $agent->get("http://rest.kegg.jp/link/pathway/$id_KEGG");
	my$rep1=$response1->content;
	#On split les données par tabulation dans une table de hash pour récupérer les id pathway
	my@ids=split("\t",$rep1);	
	foreach my$idpath (@ids){
		if (my($Path_KEGG) = $idpath =~ /path:(.+)/){
			#On effectue une expression régulière et on enregistre ce qui se trouve après le motif "path:"
		$dataset{$main_id.'_KEGG_Pathway_ID'}{$Path_KEGG}="";
		}
	}
print "KEGG => ".$main_id." OK !\n";
}
return(%dataset);
}
return 1;