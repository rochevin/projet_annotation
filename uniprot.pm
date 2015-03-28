use LWP::UserAgent;
use XML::LibXML;  
#Module qui se connecte à la base de donnée Uniprot

#Connexion à la base de données Uniprot
#en utilisant le module LWP::UserAgent
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient tous les ids uniprot correspondant au gène
sub get_all_uniprot_id {

  my ($dataset,$gene_id)=@_;

  my %dataset=%$dataset;
  my @gene_id=@$gene_id;

  my $base = 'http://www.uniprot.org';
  my $tool = 'mapping';

  #On parcours chaque id de la liste ....
  foreach my $main_id (@gene_id) {
    #On part de l'id du gene EnsEMBL
    my $id_gene=$dataset{$main_id.'_ENS_geneID'};
    my $params = {
      from => 'ENSEMBL_ID',
      to => 'ACC',
      format => 'list',
      query => "$id_gene"
    };

    #On définit un nouvel objet de type requete HTTP, en POST
    my $agent = LWP::UserAgent->new(agent => "libwww-perl");
    push @{$agent->requests_redirectable}, 'POST';


    my $rep = $agent->post("$base/$tool/", $params);
    #Et on enregistre tous les ids
    my $ids = $rep->content()."\n";
    chomp $ids; #On chomp pour pas que le dernier \n donne un element vide dans la liste
    #Qu'on insère dans une liste contenu dans dataset
    @{$dataset{$main_id.'_Uni_all_ID'}} =split("\n",$ids);
  }
  return %dataset;
}

#Connexion à la base de données Uniprot
#en utilisant le module LWP::UserAgent
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient l'id uniprot "principal" d'après l'id du transcrit canonique d'EnsEMBL
sub get_canonical_uniprot_id {

  my ($id_prot)=@_;

  my $base = 'http://www.uniprot.org';
  my $tool = 'mapping';
  my $params = {
    from => 'ENSEMBL_PRO_ID',
    to => 'ACC',
    format => 'list',
    query => "$id_prot"
  };


  my $agent = LWP::UserAgent->new(agent => "libwww-perl");
  push @{$agent->requests_redirectable}, 'POST';
  my $rep = $agent->post("$base/$tool/", $params);

  my $id = $rep->content();
  chomp $id;
  return $id;
}

#Connexion à la base de données Uniprot
#en utilisant le module XML::LibXML
#Input : Tableau de donnée dataset + liste des id Gene
#Output : %dataset qui contient : Nom de la protéine, ID PDB et lien STRING
sub get_canonical_uniprot_id_info {
  my ($dataset,$gene_id)=@_;

  my %dataset=%$dataset;
  my @gene_id=@$gene_id;

  #On parcours chaque id de la liste ....
  foreach my $main_id (@gene_id) {
    #On récupère l'id de la protéine pour faire la requête
    foreach my $elmt (keys %{$dataset{$main_id.'_ENS_canonical_transID'}}){
      $id_prot=$dataset{$main_id.'_ENS_canonical_transID'}{$elmt};
    }
    #On envoit cet id à la fonction qui va construire une requête HTTP et renvoyer un ID
    my $id = get_canonical_uniprot_id($id_prot);
    $dataset{$main_id.'_Uni_ID'}=$id;
    #On construit le lien uniprot à partir de l'id correspondant ...
    my $link = "http://www.uniprot.org/uniprot/$id.xml";
    my $parser = XML::LibXML->new();
    #Et on définit un nouveau parseur à partir du lien
    my $doc    = $parser->parse_file($link);

    #On récupère les informations des balises recommendedName
    foreach my $sample ($doc->getElementsByTagName('recommendedName')) {
      #On recupère chaque enfant de ces balises
      foreach my $elmt ($sample->childNodes()) {
        #Et on next sauf si la balise contient le nom fullname
        next unless ($elmt =~ /fullName/);
        #Dans ce cas là on enregistre le nom complet
        $dataset{$main_id.'_Uni_fullname'} = $elmt->string_value();
      }

    }

    #On fait la même chose avec dbReference
    foreach my $elmt ($doc->getElementsByTagName('dbReference')) {
      #On récupère l'id PDB
    	if (my($sub_elmt1) = $elmt =~ /type=\"PDB\" id=\"(.+)\"/ ) {
    		$dataset{$main_id.'_Uni_PDB_ID'}{$sub_elmt1}=1;
    	}
      #Et le lien STRING
      elsif (my($sub_elmt2) = $elmt =~ /type=\"STRING\" id=\"(.+)\"/ ) {
        $dataset{$main_id.'_Uni_string_ID'} = $sub_elmt2;
      }
    }
    print "Uniprot => ".$main_id." OK !\n";
  }
  #On renvoit dataset avec les informations supplémentaires
  return %dataset;
}
return 1;
