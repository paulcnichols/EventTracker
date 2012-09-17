package Story;
use StoryUtil;
use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';
our $DOCUMENT_PATH = "/Users/pnichols/Desktop/UCSD/Project/RSS/data/";

set serializer => 'JSON';

get '/' => sub {
    my $limit = params->{limit} ? int(params->{limit}) : 100;
    template 'index', {articles => StoryUtil::get_recent($limit)};
};

get '/explore/:id' => sub {
    send_error(to_json({error=>"No article id provided"}), 403) if (!params->{id});
    template 'explore', {article_id => params->{id}};
};

get '/related_graph/:id' => sub {
    send_error(to_json({error=>"No article id provided"}), 403) if (!params->{id});

    # get subgraph around id
    my $a_id = int(params->{id});
    my $graph = StoryUtil::get_subgraph($a_id);
    content_type 'application/json';
    return to_json($graph);
    
    #use GraphViz;
    #my $g = GraphViz->new();
    #
    #for my $e (@{$graph->{edges}}) {
    #    if ($e->{a_timestamp} > $e->{b_timestamp}) {            
    #        $g->add_edge($e->{article_id_a}=>$e->{article_id_b}, label=>$e->{cosign_freq});
    #    }
    #    else {
    #        $g->add_edge($e->{article_id_b}=>$e->{article_id_a}, label=>$e->{cosign_freq});
    #    }
    #}
    #for my $n (@{$graph->{nodes}}) {
    #    $g->add_node($n->{article_id}, label=>$n->{title});   
    #}
    #my $data = $g->as_png;
    #send_file( \$data, content_type => 'image/png' );
};

get '/related/:id' => sub {
    send_error(to_json({error=>"No article id provided"}), 403) if (!params->{id});
    
    # limit parameters (ignored for now)
    my $threshold = .5;
    my $limit = params->{limit} ? int(params->{limit}) : 100;
    my $term_limit = params->{term_limit} ? int(params->{term_limit}) : 25;
    my $sort = 'cosign_freq desc';
    if (params->{sort}) {
        $sort = 'cosign_freq desc' if params->{sort} eq 'cf';
        $sort = 'cosign_uniq desc' if params->{sort} eq 'cu';
        $sort = 'jaccardian desc' if params->{sort} eq 'j';
        $sort = 'euclidean_freq asc' if params->{sort} eq 'ef';
        $sort = 'euclidean_uniq asc' if params->{sort} eq 'eu';
    }
    
    # get friends
    my $id = int(params->{id});
    my $sql = qq|select *
                    from article_edge
                    where (article_id_a = $id or article_id_b = $id) and cosign_freq > $threshold
                    order by $sort
                    limit $limit|;
    my $sth = database->prepare($sql);
    my $friends = {$id=>1};
    $sth->execute();
    while (my $r=$sth->fetchrow_hashref) {
        $friends->{$r->{article_id_a}} = 1;
        $friends->{$r->{article_id_b}} = 1;
    }
    
    # get articles for friends and friends of friends
    my $ids = join(', ', keys(%$friends));
    $sql = qq|(
                    select * 
                    from article_edge
                    join article on (article_id = article_id_a)
                    join feed on (feed = feed_id)
                    where article_id_b in ($ids)
                )
                union
                (
                    select * 
                    from article_edge
                    join article on (article_id = article_id_b)
                    join feed on (feed = feed_id)
                    where article_id_a in ($ids)
                )|;
    $sth = database->prepare($sql);
    $sth->execute();
    my $articles = {};
    my $article;
    while (my $r=$sth->fetchrow_hashref) {
        if ($r->{article_id} == $id) {
            $article = $r;
        }
        else {
            push @{$articles->{$r->{date}}}, $r;
        }
    }
    
    # get terms for article
    $sql = qq|select *, tf*idf as tfidf
                                from article_term
                                join term using (term_id)
                                where article_id = $id
                                order by tfidf desc
                                limit $term_limit|;
    $sth = database->prepare($sql);
    $sth->execute();
    my $terms = [];
    while (my $r=$sth->fetchrow_hashref) {
        $r->{display} = length($r->{term}) > 15 ? substr($r->{term}, 0, 15) . '...' : $r->{term};
        push @$terms, $r;
    }
    
    template 'related', {articles => $articles, article=>$article, terms=>$terms};
};


true;
