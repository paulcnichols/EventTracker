use strict;
use warnings;
use DBI;
use Sparse::Vector;

my $dbh = DBI->connect('DBI:mysql:ucsd;host=localhost', 'root', '')
    or die "Cannot connect to database";

my $edge_insert = $dbh->prepare(qq|
                    INSERT INTO ucsd.article_edge
                    (`article_id_a`, `article_id_b`, `jaccardian`, `cosign_uniq`,
                     `cosign_freq`, `euclidean_uniq`, `euclidean_freq`)
                    VALUES
                    (?, ?, ?, ?, ?, ?, ?)|);

# get all ids between a week
sub articles_by_week {
    my $week = shift;
    my $articles = shift;
    my $limit = shift || 25;
    my $by_week = $dbh->prepare(qq|
                            SELECT *
                            FROM ucsd.article
                            WHERE 
                              date <  DATE_SUB('2012-08-13', INTERVAL  ?    WEEK) AND 
                              date >= DATE_SUB('2012-08-13', INTERVAL (?+1) WEEK)|);
    my $article_terms = $dbh->prepare(qq|
                            SELECT *, tf*idf as tfidf
                            FROM ucsd.article_term
                            WHERE article_id = ?
                            ORDER by tfidf DESC
                            LIMIT ?|);
    $by_week->execute($week, $week);
    my $ids = {};
    while (my $ref = $by_week->fetchrow_hashref()) {
        $article_terms->execute($ref->{article_id}, $limit);
        my $terms = {};
        while (my $term = $article_terms->fetchrow_hashref()) {
            # TODO: investigate indicator, frequency, and tfidf representation
            $terms->{$term->{term_id}} = $term->{tfidf};   
        }
        if (scalar(keys(%$terms))) {
            $ids->{$ref->{article_id}}++;
            $articles->{$ref->{article_id}} = $terms;
        }
    }
    return scalar(keys(%$ids)) ? [keys(%$ids)] : undef;
}

# compute various distance metrics
sub article_distance {
    my $a1 = shift;
    my $a2 = shift;
    my $a1_id = shift;
    my $a2_id = shift;
    my $intersection = {};
    my $union = {};
    my $dot = 0;
    my $a1_norm = 0;
    my $a2_norm = 0;
    for my $t (keys(%$a1)) {
        if (exists($a2->{$t})) {
            $dot += $a1->{$t} * $a2->{$t};
            $intersection->{$t} = 1;   
        }
        $union->{$t} = 1;
        $a1_norm += $a1->{$t}**2;
    }
    $a1_norm = sqrt($a1_norm);
    
    for my $t (keys(%$a2)) {
        $union->{$t} = 1;
        $a2_norm += $a2->{$t}**2;
    }
    $a2_norm = sqrt($a2_norm);
    
    my $jaccardian = (scalar(keys(%$intersection)) / scalar(keys(%$union)));
    my $cosign_uniq = scalar(keys(%$intersection)) / (sqrt(scalar(keys(%$a1))) * sqrt(scalar(keys(%$a2))));
    my $cosign_freq = $dot / ($a1_norm * $a2_norm);
    my $euclidean_uniq = 0;
    my $euclidean_freq = 0;
    for my $t (keys(%$union)) {
        $euclidean_freq += (($a1->{$t} || 0) - ($a2->{$t} || 0))**2;
        $euclidean_uniq += (($a1->{$t} ? 1 : 0) - ($a2->{$t} ? 1 : 0))**2;
    }
    $euclidean_uniq = sqrt($euclidean_uniq);
    $euclidean_freq = sqrt($euclidean_freq);
    
    $edge_insert->execute($a1_id > $a2_id ? $a1_id : $a2_id,
                          $a1_id > $a2_id ? $a2_id : $a1_id,
                          $jaccardian,
                          $cosign_uniq,
                          $cosign_freq,
                          $euclidean_uniq,
                          $euclidean_freq) if $jaccardian != 0;
}

# compute the pairwise distance on a group of ids
sub article_distance_pairwise {
    my $articles = shift;
    my $article_ids = shift;
    for (my $i=0; $i < scalar(@$article_ids)-1; ++$i) {
        for (my $j=$i+1; $j < scalar(@$article_ids); ++$j) {
            my $a1_id = $article_ids->[$i];
            my $a2_id = $article_ids->[$j];
            eval {
                article_distance($articles->{$a1_id}, $articles->{$a2_id}, $a1_id, $a2_id);
            };
            if ($@) {
                print STDERR "Error comparing $a1_id to $a2_id: $@!\n";
            }
        }
    }
}

# compute the distance on a product of two groups of ids
sub article_distance_product {
    my $articles = shift;
    my $a_ids = shift;
    my $b_ids = shift;
    for (my $i=0; $i < scalar(@$a_ids); ++$i) {
        for (my $j=0; $j < scalar(@$b_ids); ++$j) {
            my $a1_id = $a_ids->[$i];
            my $a2_id = $b_ids->[$j];
            eval {
                article_distance($articles->{$a1_id}, $articles->{$a2_id}, $a1_id, $a2_id);
            };
            if ($@) {
                print STDERR "Error comparing $a1_id to $a2_id: $@!\n";
            }
        }
    }
}

my $articles = {};
my $month = [];
my $current_week = 0;
while (my $ids = articles_by_week($current_week, $articles)) {
    
    printf STDERR "Handling week %d.\n", $current_week;

    # compute the distance interweek
    article_distance_pairwise($articles, $ids);
    
    # get the ids for the previous weeks (up to 3)
    my $month_ids=[];
    for my $week (@$month) {
        for my $id (@$week) {
            push @$month_ids, $id;
        }
    }
    
    # compute distance between week and month
    article_distance_product($articles, $month_ids, $ids) if (scalar(@$month_ids));
    
    # add week ids to month
    push @$month, $ids;
    
    # shift off week older than a month
    if (scalar(@$month) > 3) {
        my $old_ids = shift @$month;
        for my $id (@$old_ids) {
            delete($articles->{$id});
        }
    }
    
    # increment week
    ++$current_week; 
}
