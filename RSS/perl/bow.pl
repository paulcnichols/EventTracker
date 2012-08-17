use strict;
use warnings;
use List::Util qw(max);
for (my $i=1; $i <= 63; ++$i) {
    print "Directory $i\n";
    my $corpus = {};
    my $idf = {};
    for my $f (glob("../data/$i/*.html.txt")) {
        eval {
            open FH, "$f" or next;
            my $c = join("", <FH>);
            close FH;
            
            $c =~ s/\s+/ /gm;
            my $d = {};
            for my $s (split(/[^\w]/, $c)) {
                next if !length($s) or $s =~ /^\d+$/; # empty or all nums
                $d->{lc($s)}++;
            }
            
            for my $s (keys(%$d)) {
                $idf->{$s}++;
            }
            
            $corpus->{$f} = $d;
        }
    }
    
    my $D = scalar(keys(%$corpus));
    for my $f (keys(%$corpus)) {
        my $ft=[];
        my $max = max(values(%{$corpus->{$f}}));
        for my $s (keys(%{$corpus->{$f}})) {
            my $tf = $corpus->{$f}->{$s};
            my $if = 1 + $idf->{$s};
            push @$ft, {n =>$tf, tf => $tf/$max, idf=>(log($D) - log($if)), t=>$s};
        }
        open FH, ">", "$f.bow"; 
        for my $t (sort {$b->{tf}*$b->{idf} <=> $a->{tf}*$a->{idf}} @$ft) {
            print FH "$t->{n}\t$t->{tf}\t$t->{idf}\t$t->{t}\n";
        }
        close FH;
    }
}
