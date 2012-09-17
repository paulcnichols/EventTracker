package StoryUtil;
use Dancer::Plugin::Database;

# Get recent articles as a starting point
sub get_recent {
  my $limit = shift || 100;
  my $sth = database->prepare(
                  qq|select *
                      from article
                      join feed on (feed = feed_id)
                      order by date desc
                      limit ?|);
  $sth->execute($limit);
  my $articles = {};
  while (my $r=$sth->fetchrow_hashref) {
    push @{$articles->{$r->{date}}}, $r;
  }
  return $articles;
}

# Get an array of articles data
sub get_articles {  
  my $article_ids = shift or die;
  my $sth = database->prepare(
                  qq|select *
                      from article
                      where article_id = ?|);
  my $articles = [];
  for my $a (@$article_ids) {
    $sth->execute($a);
    push @$articles, $sth->fetchrow_hashref;
  }
  return $articles;
}

# Get all the edges on an article
sub get_edges {
  my $a_id = shift or die;
  my $dir = shift || '>';
  my $limit = shift || 3;
    
  my $sth = database->prepare(
                  qq|select *, a.timestamp as a_timestamp, b.timestamp as b_timestamp
                      from article_edge 
                      join article a on (article_id_a = a.article_id)
                      join article b on (article_id_b = b.article_id)
                      where euclidean_freq != 0
                      and (article_id_a = $a_id and b.timestamp $dir a.timestamp or
                           article_id_b = $a_id and a.timestamp $dir b.timestamp)
                      order by cosign_freq desc
                      limit $limit|);
  $sth->execute();
  my $edges = [];
  while (my $r=$sth->fetchrow_hashref) {
    push @$edges, $r;
  }
  return $edges;
}

# Get an articles sub-graph
sub get_subgraph {
  my $a_id = shift or die;
  my $depth = shift || 3;
  my $article = get_articles([$a_id])->[0];
  my $edges = [];
  my $articles = {$a_id=>1};
  my $upset = {$a_id=>1};
  my $downset = {$a_id=>1};
  
  for (my $n=0; $n < $depth; ++$n) {
    for my $u (keys(%$upset)) {
      delete($upset->{$u});
      my $u_edges = get_edges($u, ">");
      for my $ue (@$u_edges) {
        push @$edges, $ue;
        $articles->{$ue->{article_id_a}} = 1;
        if ($ue->{article_id_a} != $u) {
          $upset->{$ue->{article_id_a}} = 1;
        }
        $articles->{$ue->{article_id_b}} = 1;
        if ($ue->{article_id_b} != $u) {
          $upset->{$ue->{article_id_b}} = 1;
        }
      }
    }
    for my $d (keys(%$downset)) {
      delete($downset->{$d});
      my $d_edges = get_edges($d, "<");
      for my $de (@$d_edges) {
        push @$edges, $de;
        $articles->{$de->{article_id_a}} = 1;
        if ($de->{article_id_a} != $d) {
          $downset->{$de->{article_id_a}} = 1;
        }
        $articles->{$de->{article_id_b}} = 1;
        if ($de->{article_id_b} != $d) {
          $downset->{$de->{article_id_b}} = 1;
        }
      }
    }
  }
  
  return {nodes=>get_articles([keys(%$articles)]), edges=>$edges};
}

1;