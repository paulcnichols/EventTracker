use strict;
use warnings;
use HTML::TreeBuilder;
use HTML::FormatText;
for (my $i=1; $i <= 63; ++$i) {
    for my $f (glob("../data/$i/*.html")) {
        next if -e "$f.txt";
        eval {
            open FH, ">", "$f.txt";
            print FH HTML::FormatText->new->format(HTML::TreeBuilder->new->parse_file($f));
            close FH;
        };
        if ($@) {
            `rm $f.txt` if -e "$f.txt";
        }
    }
}
