use strict;
use warnings;

use DBI;
my $dbh = DBI->connect('DBI:mysql:ucsd;host=localhost', 'root', '')
    or die "Cannot connect to database";

my $article_insert =  $dbh->prepare(qq|INSERT INTO ucsd.article (feed, timestamp) VALUES (?,?)|);

my $term_insert = $dbh->prepare(qq|
                            INSERT INTO ucsd.term
                            (term,count)
                            VALUES
                            (?,1)
                            ON DUPLICATE KEY UPDATE
                                term_id=LAST_INSERT_ID(term_id),
                                count=count + 1|);

my $article_term_insert = $dbh->prepare(qq|
                            INSERT IGNORE INTO ucsd.article_term
                            (article_id, term_id, count, tf, idf)
                            VALUES
                            (?,?,?,?,?)|);

my $lii = $dbh->prepare(qq|SELECT LAST_INSERT_ID()|);

sub article_id {
    my $feed = shift;
    my $timestamp = shift;
    $article_insert->execute($feed, $timestamp);
    $lii->execute();
    return $lii->fetchrow_arrayref->[0];
}

sub term_id {
    my $t = shift;
    $term_insert->execute($t);
    $lii->execute();
    return $lii->fetchrow_arrayref->[0];
}

sub article_term {
    my $aid = shift;
    my $tid = shift;
    my $n = shift;
    my $tf = shift;
    my $idf = shift;
    $article_term_insert->execute($aid, $tid, $n, $tf, $idf);
}

for (my $i=1; $i <= 63; ++$i) {
    for my $f (glob("../data/$i/*.bow")) {
        print "$f...\n";
        
        $f =~ /(\d+)\.html\.txt\.bow/;
        my $timestamp = $1;
        my $aid = article_id($i, $timestamp);

        open FH, $f or next;
        while(<FH>) {
            chomp;
            my ($n, $tf, $idf, $t) = split(/\t/);
            my $tid = term_id($t);
            article_term($aid, $tid, $n, $tf, $idf);
        }
        close FH;
    }
}