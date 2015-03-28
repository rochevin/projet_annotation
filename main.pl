#!/usr/bin/perl

use warnings;
use strict;
use NCBI;
use uniprot;
use EnsEMBL;
use PDB;
use kegg;
use prosite;
use pfam;
use GO;
use Data::Dumper;

#On ouvre le fichier contenant la liste des genes
my $nom_fichier = $ARGV[0];
unless ( open(gene_list, $nom_fichier) ) {
    print STDERR "\"$nom_fichier\" can't be found...\n\n";
    exit;
}

my %gene_orga_list;

foreach my $line (<gene_list>) {
	next if ( $line =~ /^\s*$/ );
	next if ( $line =~ /^#/ );
	chomp $line;
	my @info_ligne = split("\t", $line);
	$gene_orga_list{$info_ligne[0]}{$info_ligne[1]}="";
}
close gene_list;
#Début du programme principal
print "####################################################\n";
print "#                                                  #\n";
print "#     Program : Get annotations from databases     #\n";
print "#   Use : BioPerl, API EnsEMBL, LWP and Lib::XML   #\n";
print "#     Author : Vincent ROCHER & Mathieu GACHET     #\n";
print "#                                                  #\n";
print "####################################################\n";
print "####################################################\n";
print "#Connexion à la base de donnée Gene... \n";
print "##Création de la requête à partir de la liste de gènes : \n";
my ($gene_id,$dataset)=get_gene_id(\%gene_orga_list); #On récupère les ids Gene pour chaque gene symbol et l'organisme correspondant
my @gene_id=@$gene_id; #On enregistre les ids Gene ex : 5888
my %dataset=%$dataset; #Tableau associatif qui va contenir les données sur tous les genes
%dataset=get_gene_table(\%dataset,\@gene_id); #On récupère les données à partir de la base Gene
%dataset=get_unigene_id(\%dataset,\@gene_id);
print "#Connexion à la base de donnée EnsEMBL... \n";
%dataset=get_ensembl_id(\%dataset,\@gene_id);

print "#Connexion à la base de donnée Uniprot... \n";
%dataset = get_all_uniprot_id(\%dataset,\@gene_id);
%dataset=get_canonical_uniprot_id_info(\%dataset,\@gene_id);
print "#Connexion à la base de donnée PDB... \n";
%dataset=get_PDB_info(\%dataset,\@gene_id);
print "#Connexion à la base de donnée KEGG... \n";
%dataset=get_kegg_info(\%dataset,\@gene_id);
print "#Connexion à la base de donnée Prosite... \n";
%dataset=get_proS_info(\%dataset,\@gene_id);
print "#Connexion à la base de donnée Pfam... \n";
%dataset=get_pfam_info(\%dataset,\@gene_id);
print "#Connexion à la base de donnée GO... \n";
%dataset=get_GO_info(\%dataset,\@gene_id);
print "####################################################\n";

#Permet de voir le contenu et la structure de dataset une fois les annotations enregistrés
print Dumper(sort \%dataset);




unless ( open(json_file, ">datatables/ajax/data/Data.txt") ) {
    print STDERR "Impossible de créer le fichier ...\n\n";
    exit;
}

#On commence à écrire dans le fichier json
	print json_file '
		{
    "data": [';
my $taille = scalar @gene_id; #On determine le nombre d'élement pour suprimmer la dernière virgule
my $compteur = 0; #Et on définit un compteur pour savoir ou on en est
foreach my $main_id(@gene_id){
	print json_file '
             {
            "Name":"<table style=\'width:150px;\'><thead><tr><th>Gene symbol</th></thead><tr><td><a href=\'http://www.ncbi.nlm.nih.gov/gene/'.$main_id.'\'>'.$dataset{$main_id."_Gene_Symbol"}.' - '.$dataset{$main_id.'_Taxonomy_Name'}.'('.$dataset{$main_id.'_Taxonomy_ID'}.')</td></tr></table>",
            "NCBI":"<table style=\'width:500px\'><thead><tr><th>Official Full Name</th><th>Transcrit Access Number</th><th>Protein Access Number</th></thead><tr><td>'.$dataset{$main_id."_Gene_fullname"}.'</td><td>';

    foreach my $elmt (keys %{$dataset{$main_id.'_RS_transID'}}) {
    	print json_file " <br> <a href='http://www.ncbi.nlm.nih.gov/nuccore/".$elmt."'>".$elmt."</a>";
    }
    print json_file "</td><td>";
    foreach my $elmt (keys %{$dataset{$main_id.'_RS_transID'}}) {
    	print json_file " <br> <a href='http://www.ncbi.nlm.nih.gov/protein/".$dataset{$main_id.'_RS_transID'}{$elmt}."'>".$dataset{$main_id.'_RS_transID'}{$elmt}."</a>";
    }
    print json_file '</td></tr></table>",';
    print json_file '"Ensembl":"<table style=\'width:700px\'><thead><tr><th>Gene Access Number</th><th>Location</th><th>Transcrit Access Number</th><th>Protein Access Number</th></thead><tr><td><a href=\'http://www.ensembl.org/Gene/Summary?g='.$dataset{$main_id."_ENS_geneID"}.'\'>'.$dataset{$main_id."_ENS_geneID"}.'</a></td><td><a href=\'http://www.ensembl.org/'.$dataset{$main_id.'_Taxonomy_Name'}.'/Location/View?db=core;r='.$dataset{$main_id."_ENS_browserLOC"}.'\'>'.$dataset{$main_id."_ENS_browserLOC"}.'</a></td>';

    foreach my $elmt (keys %{$dataset{$main_id.'_ENS_canonical_transID'}}){
		print json_file "<td><a href='http://www.ensembl.org/".$dataset{$main_id.'_Taxonomy_Name'}."/Transcript/Summary?db=core;g=ENSG00000051180;t=".$elmt."'>".$elmt."</a></td><td>".$dataset{$main_id.'_ENS_canonical_transID'}{$elmt}."</td>";
	}

    print json_file	
    		'</tr></table>",
            "Uniprot":"<table style=\'width:400px\'><thead><tr><th>Protein name</th><th>Protein Access Number</th></thead><tr><td>'.$dataset{$main_id."_Uni_fullname"}.'</td><td><a href=\'http://www.uniprot.org/uniprot/'.$dataset{$main_id."_Uni_ID"}.'\'>'.$dataset{$main_id."_Uni_ID"}.'</a></td></tr><tr><td colspan=\'2\'><b>All Uniprot ID : </b>';
    my $print_uni_id="";
    foreach my $elmt (@{$dataset{$main_id.'_Uni_all_ID'}}) {
    	$print_uni_id .= "<a href='http://www.uniprot.org/uniprot/".$elmt."'>".$elmt."</a>, ";
    }
    print json_file substr ($print_uni_id,0,-2);
    print json_file '</td></tr></table>",
            "Prosite":"<table style=\'width:300px\'><thead><tr><th>Domain Access Number</th></thead><tr><td>';
    foreach my $elmt (keys %{$dataset{$main_id.'_PS_ID'}}) {
    	print json_file " <br> <a href='http://prosite.expasy.org/".$elmt."'>".$elmt."</a>(".$dataset{$main_id.'_PS_info_'.$elmt}{"ID_Name"}.")";
    }
    print json_file
            '</td></tr></table>",
            "Pfam":"<table style=\'width:200px\'><thead><tr><th>Access Number</th></thead><tr><td>';
    foreach my $elmt (keys %{$dataset{$main_id.'_PF_ID'}}) {
    	print json_file " <br> <a href='http://pfam.xfam.org/family/".$elmt."'>".$elmt."</a>(".$dataset{$main_id.'_PF_info_'.$elmt}{"Id"}.")";
    }
    print json_file
            '</td></tr></table>",
            "KEGG":"<table style=\'width:300px\'><thead><tr><th>Access Number</th><th>Pathway Access Number</th></thead><tr><td><a href=\'http://www.genome.jp/dbget-bin/www_bget?'.$dataset{$main_id."_KEGG_ID"}.'\'</a>'.$dataset{$main_id."_KEGG_ID"}.'</td><td>';
    foreach my $elmt (keys %{$dataset{$main_id.'_KEGG_Pathway_ID'}}) {
    	print json_file "<a href='http://rest.kegg.jp/get/".$elmt."/image'>".$elmt."</a>, ";
    }
    print json_file '</td></tr></table>",';
    if (exists $dataset{$main_id."_Uni_string_ID"}) {
	    print json_file
	            '"Protein_Int":"<table style=\'width:200px\'><td><a href=\'http://string-db.org/newstring_cgi/show_network_section.pl?identifier='.$dataset{$main_id."_Uni_string_ID"}.'\'>'.$dataset{$main_id."_Uni_string_ID"}.'</a></td></tr></table>",';
    }
    else {
	    print json_file
	            '"Protein_Int":"<table style=\'width:200px\'><td>NONE</td></tr></table>",';
    }
    print json_file '"PDB":"<table style=\'width:400px\'><thead><tr><th>Structural Access Number</th></thead><tr><td>';
    if (exists $dataset{$main_id.'_Uni_PDB_ID'}){
	    foreach my $elmt (keys %{$dataset{$main_id.'_Uni_PDB_ID'}}) {
	    	print json_file "<b><a href='http://www.rcsb.org/pdb/explore.do?structureId=".$elmt."'>".$elmt."</a></b>";
	    	foreach my $elmt2 (@{$dataset{$main_id.'_PDB_struct_info_'.$elmt}}) {
	    		print json_file "(".$elmt2."), ";
	    	}
	    }
	}
	else {
		print json_file 'NONE';
	}
    print json_file
            '</td></tr></table>",
            "idtrans": "';
    foreach my $elmt (keys %{$dataset{$main_id.'_ENS_transID'}}){
		print json_file " <br> <a href='http://www.ensembl.org/".$dataset{$main_id.'_Taxonomy_Name'}."/Transcript/Summary?db=core;g=ENSG00000051180;t=".$elmt."'>".$elmt."</a> => ".$dataset{$main_id.'_ENS_transID'}{$elmt};
	}

	print json_file '",
            "PS_Limits":"<table><thead><tr><th>Domain ID(start-end)</th></thead><tr><td>';
    foreach my $elmt (keys %{$dataset{$main_id.'_PS_ID'}}) {
    	print json_file " <br> <a href='http://prosite.expasy.org/".$elmt."'>".$elmt."</a>(".$dataset{$main_id.'_PS_info_'.$elmt}{'start'}."-".$dataset{$main_id.'_PS_info_'.$elmt}{'end'}.")";
    }
    print json_file '</td>';
    if (exists $dataset{$main_id.'_PS_ID'}) {
    	print json_file '<td><img src=\'http://prosite.expasy.org/cgi-bin/prosite/PSImage.cgi?hit=';
    	my @end;
    	my $link;
	    foreach my $elmt (keys %{$dataset{$main_id.'_PS_ID'}}) {
	    	$link .= $dataset{$main_id.'_PS_info_'.$elmt}{'start'}.",".$dataset{$main_id.'_PS_info_'.$elmt}{'end'}.",".$elmt.",".$dataset{$main_id.'_PS_info_'.$elmt}{'ID_Name'}."+";
	    	push @end,$dataset{$main_id.'_PS_info_'.$elmt}{'end'} #Pour enregistrer la longueur max
	    }
	    $link = substr ($link,0,-1);
	    print json_file $link;
	    print json_file '&type=1&len=';
	    @end = sort @end; #On trie la liste dans l'ordre croissant
	    print json_file $end[-1]; #On print la valeur max
	    print json_file '&hscale=0.6\' alt=\'\' /></td></tr></table>",
	            "GO":"<table><tr><td><b>Function : </b>';
	}
    foreach my $elmt (keys %{$dataset{$main_id.'_GO_ID'}}) {
    	next unless ($dataset{$main_id.'_GO_info_'.$elmt}{'categorie'} eq 'Function');
    	print json_file "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id=".$elmt."'><span TITLE='".$dataset{$main_id.'_GO_info_'.$elmt}{'Go_Name'}."'>".$elmt."</span></a>, ";
    }			
		print json_file	' <br> <b>Process : </b>';
	foreach my $elmt (keys %{$dataset{$main_id.'_GO_ID'}}) {
    	next unless ($dataset{$main_id.'_GO_info_'.$elmt}{'categorie'} eq 'Process');
    	print json_file "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id=".$elmt."'><span TITLE='".$dataset{$main_id.'_GO_info_'.$elmt}{'Go_Name'}."'>".$elmt."</span></a>, ";
    }
		print json_file	' <br> <b>Component : </b>';
	foreach my $elmt (keys %{$dataset{$main_id.'_GO_ID'}}) {
    	next unless ($dataset{$main_id.'_GO_info_'.$elmt}{'categorie'} eq 'Component');
    	print json_file "<a href='http://www.ebi.ac.uk/QuickGO/GTerm?id=".$elmt."'><span TITLE='".$dataset{$main_id.'_GO_info_'.$elmt}{'Go_Name'}."'>".$elmt."</span></a>, ";
    }
    $compteur++;
    if ($compteur!=$taille){
    	print json_file	'</td></tr></table> "
        },
	';
    }
    elsif ($compteur==$taille){
    	print json_file	'</td></tr></table> "
        }
	';
    }	
}
print json_file ']
	}';
close json_file;

