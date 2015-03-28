#!/usr/bin/perl
use XML::LibXML;

#Connexion à la base de données Pfam
#en utilisant le module XML::LibXML
#Input : Liste des genes symbol et organismes
#Output : %dataset qui contient : Numéro d'accession et sa description
sub get_pfam_info{
my ($dataset,$gene_id)=@_; #On récupère dataset et la liste des ids
my %dataset=%$dataset;
my @gene_id=@$gene_id;

#On définit un parseur XML via la librairie XML::LibXML
$parser = new XML::LibXML;
#Pour chaque élément la liste ...

foreach my $main_id(@gene_id){
	#On enregistre l'identifiant uniprot de l'id contenu dans dataset dans une variable
	my $accession_uniprot=$dataset{$main_id."_Uni_ID"};
	#On parse la page correspondant à cet identifiant
	$struct = $parser -> parse_file("http://pfam.xfam.org/protein/$accession_uniprot?output=xml");
	#Les balises qui nous intérèssent sont les enfants de la balise matches
	foreach $elmt($struct->getElementsByTagName('matches')){
		foreach $elmt2($elmt->childNodes()){
			#Les informations sont dans la balise match
			if ($elmt2 =~ /match/){
				$PF=$elmt2->getAttribute('accession'); #On récupère le numero d'accession
				$Id_PF=$elmt2->getAttribute('id'); #Description du numéro
				#On enregistre dans dataset
				$dataset{$main_id.'_PF_ID'}{$PF}=""; 
				$dataset{$main_id.'_PF_info_'.$PF}{'Id'}=$Id_PF;
			}
		}
	}
	print "Pfam => ".$main_id." OK !\n";
}
#On renvoit dataset
return(%dataset);
}
return 1;

