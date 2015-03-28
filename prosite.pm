#!/usr/bin/perl
use XML::LibXML;


#Connexion à la base de données Prosite
#en utilisant le module XML::LibXML
#Input : Liste des genes symbol et organismes
#Output : %dataset qui contient : Numéro d'accession et sa description, début fin du domaine
sub get_proS_info{
my ($dataset,$gene_id)=@_;#On récupère le tableau des genes symbol
my%dataset=%$dataset;
my@gene_id=@$gene_id;
#On définit un parseur XML via la librairie XML::LibXML
$parser = new XML::LibXML;
#Pour chaque élément la liste ...
foreach my$main_id(@gene_id){
	#On enregistre l'identifiant uniprot de l'id contenu dans dataset dans une variable
	my $accession_uniprot=$dataset{$main_id."_Uni_ID"};
	#On parse la page correspondant à l'identifiant
	$struct = $parser -> parse_file("http://prosite.expasy.org/cgi-bin/prosite/PSScan.cgi?seq=$accession_uniprot&output=xml");
	foreach $elmt($struct->getElementsByTagName('match')){
		foreach $elmt2($elmt->childNodes()){
			if ($elmt2 =~ /signature_ac/){
				$PS=$elmt2->string_value();
				
			}
			elsif ($elmt2 =~ /start/){
				$start=$elmt2->string_value();
				
			}
			elsif ($elmt2 =~ /stop/){
				$end=$elmt2->string_value();
				
			}
			elsif ($elmt2 =~ /signature_id/){
				$id=$elmt2->string_value();
				
			} 
		}
		$dataset{$main_id.'_PS_ID'}{$PS}="";
		$dataset{$main_id.'_PS_info_'.$PS}{'start'}=$start;
		$dataset{$main_id.'_PS_info_'.$PS}{'end'}=$end;
		$dataset{$main_id.'_PS_info_'.$PS}{'ID_Name'}=$id;
	}
	print "Prosite => ".$main_id." OK !\n";
}
return(%dataset);
}
return 1;