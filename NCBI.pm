use Bio::DB::EUtilities;
use Bio::DB::Taxonomy;
use Bio::DB::EntrezGene;
#Module qui se connecte aux bases de données du NCBI

#Connexion à la base de données Gene 
#en utilisant la fonction esearch de EUtilities
#Input : Liste des genes symbol et organismes
#Output : %dataset qui contient : Nom de l'espèce, son taxon, le gene symbol pour chaque id Gene
sub get_gene_id {
	my ($gene_orga_list)=@_; #On récupère le tableau des genes symbol

	my %gene_orga_list=%$gene_orga_list;
	my %dataset; #On déclare la table de Hash dataset qui contiendra toutes nos données
	my $query;
	my @ids;
	#On fait une boucle pour construire la requête avec chaque gene symbol
	#et son organisme correspondant
	foreach my $gene_symbol (sort keys %gene_orga_list) {#On parcours les genes symbol
		foreach my $orga (sort keys %{$gene_orga_list{$gene_symbol}}){#On parcours les organismes de chaque gene symbol
			$query = "$gene_symbol\[sym\] AND $orga\[Organism\]";
			print "##".$query;
			my $factory = Bio::DB::EUtilities->new(
				-eutil => 'esearch', 
				-db => 'Gene',
			    -term => $query, 
			    -email => 'vincent.rocher@etu.univ-rouen.fr',
			    -retmax => 5000
			);
			#On récupère tous les ids sous la forme d'une liste
			my @id = $factory->get_ids;
			$dataset{$id[0].'_Taxonomy_ID'}=get_taxon_id($orga); #On recupère l'id du taxon avec la fonction get_taxon_id
			$dataset{$id[0].'_Gene_Symbol'}=$gene_symbol; #On place le Gene Symbol
			$dataset{$id[0].'_Taxonomy_Name'}=$orga; #On place le nom de l'espèce
			next unless($id[0] =~ /^[0-9]+$/);
			print " => ".$id[0]."\n";
			push @ids,$id[0];

		}
	}

	#On renvoit la liste des ids et notre dataset
	return \@ids,\%dataset;
}


#Connexion à la base de données Taxonomy 
#en utilisant la fonction Bio::DB::Taxonomy
#Input : Un nom d'organisme
#Output : Le taxon
sub get_taxon_id {
	my ($name) = @_; #On récupère un nom d'organism

	#On se connecte à la base de donnée Taxonomy
	my $db = Bio::DB::Taxonomy->new(-source => 'entrez');
	#On soumet le nom de l'organisme
	my $taxonid = $db->get_taxonid($name);
	#On recupère le taxon
	return $taxonid;#On renvoit le taxon
}


#Connexion à la base de données Gene 
#en utilisant la fonction esearch de EUtilities
#Input : %dataset et notre liste d'id Gene
#Output : %dataset qui contient : Le nom complet du gene, l'id du Gène, l'id des transcrits et des proteines correspondantes
sub get_gene_table {

	my ($dataset,$gene_id)=@_; #On récupère dataset et la liste des ids
	my %dataset = %$dataset;
	my @gene_id = @$gene_id;

	#Pour chaque id de la liste...
	foreach my $main_id (@gene_id) {
		#On se connecte à la base via Eutilities et on soumet l'id
		my $factory = Bio::DB::EUtilities->new(
			-eutil =>'efetch',
			-db => 'Gene',
			-id => $main_id,
			-email => 'vincent.rocher@etu.univ-rouen.fr',
			-rettype => 'gene_table',
			-retmode => 'text'
		);
		#On récupère la réponse dans une liste
		my @result=split('\n',$factory->get_Response->content);
		#On récupère le nom complet via une expression régulière
		($dataset{$main_id.'_Gene_fullname'})=($result[0] =~ /\w+ (.+)\[/ );
		#Pour chaque ligne de la liste...
		foreach my $ligne (@result) {
			#On récupère un transcrit et sa protéine
			if(my($id1,$id2)=$ligne =~ /(NM_[^\s,]+).+(NP_[^\s,]+)/ ){
				$dataset{$main_id.'_RS_transID'}{$id1}=$id2;
			}
			#Si il n'y a pas de proteines on marque "none"
			elsif (my($id)=$ligne =~ /(NM_[^\s,]+)/ ){
				$dataset{$main_id.'_RS_transID'}{$id}="none";
			}
			#On récupère l'id du gene
			elsif(my($id_gene)=$ligne =~ /(NC_[^\s,]+)/ ){
				$dataset{$main_id.'_RS_geneID'}=$id_gene;

			}
		}
		print "Gene => ".$main_id." OK !\n";
	}
	#On renvoit dataset
	return %dataset;
}
#Connexion à la base de données Gene 
#en utilisant la fonction Bio::DB::EntrezGene
#Input : Liste des genes symbol et organismes
#Output : %dataset qui contient : L'id Unigene
sub get_unigene_id {

	my ($dataset,$gene_id)=@_; #On récupère dataset et la liste des ids

	my %dataset=%$dataset;
	my @gene_id=@$gene_id;
	#Pour chaque id de la liste ...
	foreach my $main_id (@gene_id) {

		$db = Bio::DB::EntrezGene->new;
		#On récupère le contenu en soumettant l'id
		$seq = $db->get_Seq_by_id($main_id);
		#On récupère les annotations
		$annotation = $seq->annotation;


		my @UniGene_ids;
		#On recupère les noms des annotations et on les parcours
		foreach $elmt ( $annotation->get_all_annotation_keys() ) {
			my @values = $annotation->get_Annotations($elmt);
			#On next sauf si l'annotation est dblink
			next unless ($elmt =~ /dblink/);
			#Si c'est le cas on parcours pour recupèrer l'id UniGene
			foreach my $value ( @values ) {
				my $info = $value->display_text();
				next unless (my ($id) = $info =~ /UniGene:(.+)/); 
				push @UniGene_ids, $id;
			}
		}
		#On enregistre le contenu dans dataset
		@{$dataset{$main_id.'_UniGeneID'}}=@UniGene_ids;
		print "UniGene => ".$main_id." OK !\n";
	}
	#Et on renvoit
	return %dataset;
}

return 1;