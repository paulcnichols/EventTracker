use strict;
use warnings;
use DBI;
use JSON qw(from_json);

my $dbh = DBI->connect('DBI:mysql:ucsd;host=localhost', 'root', '')
    or die "Cannot connect to database";

my $article_update = $dbh->prepare(qq|
                            UPDATE ucsd.article
                                set title=?
                            WHERE
                                feed = ? AND
                                timestamp = ?|);

sub article {
    my $feed = shift;
    my $timestamp = shift;
    my $title = shift;
    $article_update->execute($title, $feed, $timestamp);
}

for (my $i=1; $i <= 63; ++$i) {
    for my $f (glob("../data/$i/*.json")) {
        print "$f...\n";
        open FH, $f or next;
        my $title = from_json(join("", <FH>))->{title};
        close FH;
        
        $f =~ /(\d+)\.json/;
        my $timestamp = $1;
        my $aid = article($i, $timestamp, $title);
    }
}