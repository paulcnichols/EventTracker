use JSON qw(from_json);
use Regexp::Common qw(URI);

for (my $i=1; $i <= 63; ++$i) { 
    for my $f (glob("../data/$i/*.json")) { 
        open FH, $f; 
        my $c=from_json(join("", <FH>)); 
        close FH;
        
        $f =~ s/$i\///; 
        $f =~ s/\.json//;
        
        $c->{content}->{content} =~ s/<(?:[^>'"]*|(['"]).*?\1)*>/ /gs;
        $c->{content}->{content} =~ s/hxxp/http/gi; 
        $c->{content}->{content} =~ s/$RE{URI}{HTTP}/__URL__/gi;

        open FH, ">", "../data-clean/$i-$f.txt"; 
        print FH $c->{content}->{content}; 
        close FH 
    } 
}
