use XML::LibXML;  
#Module qui se connecte à la base de donnée PDB

#Connexion à la base de données PDB
#en utilisant le module XML::LibXML
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient les informations structurales de chaque ID PDB
sub get_PDB_info {
	my ($dataset,$gene_id)=@_;

	my %dataset=%$dataset;
	my @gene_id=@$gene_id;
	#Pour chaque id dans la liste ...
	foreach my $main_id (@gene_id) {
		#Et pour chaque id PDB correspondant ...
		foreach my $PDB_id (keys %{$dataset{$main_id.'_Uni_PDB_ID'}}) {
			#On définit un nouvel objet LibXML à partir du fichier xml correspondant à l'id PDB
			my $doc = XML::LibXML->new()->parse_file("http://www.rcsb.org/pdb/files/$PDB_id.xml");

			my $tagname = "PDBx:pdbx_fragment";
			my @structural_info;
			#Si il existe un tag portant le nom pdbx_fragment
			if ($doc->getElementsByTagName($tagname)) {
				#On parcours les éléments de ce tag qu'on enregistre dans une liste
				foreach my $elmt ($doc->getElementsByTagName($tagname)) {
					push @structural_info,$elmt->string_value();
				}
			}
			#Sinon on considère qu'il n'y a pas d'information structurale correspondant à l'id
			else {
				push @structural_info,"None";
			}
			#On enregistre le tout dans une liste contenu dans dataset
			@{$dataset{$main_id.'_PDB_struct_info_'.$PDB_id}}=@structural_info;
			#Ainsi que le lien correspondant à la structure 3D en image
			$dataset{$main_id.'_PDB_struct_link_'.$PDB_id}="http://www.rcsb.org/pdb/images/".$elmt."_bio_r_500.jpg";
		}
		print "PDB => ".$main_id." OK !\n";
	}
	#On renvoit le tableau associatif avec les nouvelles données
	return %dataset;
}

return 1;
