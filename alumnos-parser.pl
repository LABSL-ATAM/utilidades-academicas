#!/usr/bin/perl

# use strict;
use warnings;
use Switch;
use feature 'say';
# binmode(STDOUT, ":utf8");
use Data::Dumper;
use Text::CSV;
use Text::Roman qw(:all);

use List::MoreUtils "uniq";

use Encode qw(encode decode);
my $enc = 'utf-8'; # This script is stored as UTF-8





my $file = $ARGV[0]
	or die "\n\n Declarar fichero CSV como 1er parámetro \n\n";


my $csv = Text::CSV->new ({
	  binary    => 1,
	  auto_diag => 1,
});

open(my $data, '<:encoding(utf8)', $file) 
	or die "No puedo abrir el fichero '$file' $!\n";

my $array_field = 'asignaturas'; #este es el campo @array con las materias.

my @headers;
my @materias;
my %alumnos;

my $cantidad_lineas = 0;
while (my $fields = $csv->getline($data)) {
$cantidad_lineas++;
	my $id = $fields->[4];

	# cargo los headers del CSV a @headers
	if($fields->[0] eq 'apellido'){
		@headers = @{$fields};	
		#if($ARGV[1] eq '') die "oeoe"
		next;
	}


	# uso los cada header como keys en un hash temporal
	my %current_hash;
	my $n_field = 0;
	foreach (@headers) {

		$current_hash{$_} = $fields->[$n_field];
		$n_field++;	
	} 


	# si el alumno ya esta convertir valor '$array_field' en array y pupulate it :)
	my @temp_array;
	if($alumnos{$id}){
		
		if(ref($alumnos{$id}{$array_field}) eq 'ARRAY'){

			push (@{$alumnos{$id}{$array_field}},$current_hash{$array_field});
			my @A = uniq(@{$alumnos{$id}{$array_field}});

			$alumnos{$id}{$array_field} = \@A;

		}else{
			push (@temp_array, $alumnos{$id}{$array_field});
			push (@temp_array, $current_hash{$array_field});

			my @A = uniq(@temp_array);
			$alumnos{$id}{$array_field} = \@A;

		}

	}else{
		$alumnos{$id} = \%current_hash;
		push (@materias, $alumnos{$id}{$array_field}); # al array @materias
	}
	 	 
}
@materias = uniq(@materias);

if (not $csv->eof) {
  	$csv->error_diag();
}
close $data;


my $encabezado = 

"################################################################################".  "\n".
"Universidad Nacional de las Artes                             C.A.B.A, Argentina".  "\n".
"Área Transdapertamental de Artes Multimediales                    Noviembre 2016".  "\n".
"Secretaría Académica / Sistemas".  "\n".
"\n"."\n"."\n".
"REPORTE INSCRIPTOS 1ER CUATRIMESTRE 2016"."\n".
"\n"
;

say $encabezado;

my $cantidad_alumnos =  scalar(keys %alumnos);  # prints 3
my $info = $cantidad_alumnos. " REGISTROS DE ".$cantidad_lineas. " LINEAS PROCESADAS";
say $info."\n";

foreach my $alumno (
	sort { 
        lc($alumnos{$a}->{apellido}) cmp 
        lc($alumnos{$b}->{apellido}) 
    } 
	keys %alumnos
){
	imprimirAlumnoCompleto($alumno);
}

say "################################################################################"; 



my $hr_st = '';
$hr_st .="# HEADERS #############\n";
foreach (@headers) {
	$hr_st .= $_."\n";
} 
# say $hr_st;


## Subs Mias

sub imprimirAlumnoCompleto{
    my $alumno = $_[0];
    say "--------------------";
    my $apellido = uc($alumnos{$alumno}{apellido});
    my $nombres =  tc($alumnos{$alumno}{nombres});
    my $asignaturas =  join( ', ', sort @{$alumnos{$alumno}{asignaturas}});
    #$asignaturas =~ s/(.{1,65})/$1\n/gs;
    #my $sexo = $alumnos{$alumno}{sexo};
    my $documento_tipo = $alumnos{$alumno}{documento_tipo};
    my $documento_nro = $alumnos{$alumno}{documento_nro};
    my $e_mail = $alumnos{$alumno}{e_mail};
    my $telefono = $alumnos{$alumno}{telefono};

    my $st = encode( $enc, 
        $apellido." ".$nombres.  "\n".
        "MATERIAS: ". $asignaturas.".\n".
        #"SEXO: " . $sexo.  "\n".
        $documento_tipo.": ".$documento_nro.  "\n".
        "CORREO: ".$e_mail.  "\n".
        "TEL: ". $telefono
    );
    say $st;

}



sub romanosToArabicos{
	my $s = $_[0];

	my @array_s = (split ' ',$s);
	my $last_word = $array_s[-1];
	
	if (isroman($last_word)){
		$array_s[-1] = roman2int($last_word);
	}
	
	return join(' ', @array_s); 
}  


## Subs Ajenas

# tc("to say it once");
sub tc{
 	my $text = $_[0];
 	$text =~ s/(\w+)/\u\L$1/g;
	return $text;
}

# rs("   The   perl      ");
sub rs{
 	my $text = $_[0];
 	
	# remove leading whitespace
	$text =~ s/^\s+//;
	# remove trailing whitespace
	$text =~ s/\s+$//;
	return $text;
}

## Siglas asignaturas
sub abbr {
	my %opt = @_;

	die("Sorry, I can't return an abbreviation if you don't give me a name.") 
		if !$opt{name};

	my $name = $opt{name};

	$name = romanosToArabicos($name); #llama a sub mia

#	my $remove = 'The|A|An|de';

	$name =~ s/^(The|A|An|) //i;

	if ($name !~ /[ _-]/) {
		return $opt{name};
	
	}else {
        my @abbr;
        for my $word (split(/[ _-]/,$name)) {
            push @abbr, substr($word,0,1);
        }
        my $raw_abbr = 
            $opt{periods} && 
            $opt{periods} =~ /^[yt1]/i ? 
                join( '', map { $_ =~ s/$/./; $_; } @abbr) : 
                join( '', @abbr);

        my $out = $opt{REMOVElc} && 
            !$opt{ALLCAPS} ? 
                $raw_abbr =~ s/[a-z]/''/ge : 
                $raw_abbr; #agregado mio

        my $final_abbr = $opt{ALLCAPS} && 
            $opt{ALLCAPS} =~ /^[yt1]/i ? 
                uc $raw_abbr : 
                $raw_abbr;

        if (
            $opt{HTML} && $opt{HTML} =~ 
            /^[yt1]/i
        ){
          return qq(<abbr title="$opt{name}">$final_abbr</abbr>);
        }
        else {
          return $final_abbr;
        }
  }
}


sub initials {
  my %opt = @_;
  
  my $initials = abbr(
    name => $opt{name} ? $opt{name} : 
    	die("Sorry, I can't return initials if you don't give me a name."),

    periods => $opt{periods} ? $opt{periods} : undef,
    ALLCAPS => $opt{ALLCAPS} ? $opt{ALLCAPS} : undef,
    REMOVElc => $opt{REMOVElc} ? $opt{REMOVElc} : "yes", 
    HTML => $opt{HTML} ? $opt{HTML} : undef,
  );
  
  return $initials;
}






