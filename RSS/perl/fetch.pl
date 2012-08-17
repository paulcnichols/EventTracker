use strict;
use warnings;
use JSON qw(from_json to_json);
use LWP::Simple;

my $feeds = {};
my $feed_id = 0;
while (my $url = <>) {
    print "Handling $url";
    
    $url =~ s/\s+$//;
    my $feed = get("http://www.google.com/reader/api/0/stream/contents/feed/$url?n=250");
    next if !length($feed);
    eval {
        $feed = from_json($feed);
    };
    next if $@;
    
    # remove extra information
    my $items = delete($feed->{items});
    delete($feed->{self});
    if (!exists($feeds->{$url})) {
        $feeds->{$url} = $feed;
        $feeds->{$url}->{fid} = ++$feed_id;
        `mkdir ../data/$feed_id` if !-d "../data/$feed_id";
    }
    next if $url eq "http://www.exploit-db.com/feed/";
    
    my $fid = $feeds->{$url}->{fid};
    for my $i (@$items) {
        next if !exists($i->{alternate}) or !exists($i->{alternate}->[0]);
        print "$i->{alternate}->[0]->{href}\n";
        
        if (!-e "../data/$fid/$i->{published}.json") {
            open FH, ">", "../data/$fid/$i->{published}.json" or next;
            print FH to_json($i);
            close FH;
        }
        
        if (!-e "../data/$fid/$i->{published}.html") {
            open FH, ">", "../data/$fid/$i->{published}.html" or next;
            binmode FH, ":utf8";
            print FH get($i->{alternate}->[0]->{href});
            close FH;
        }
    }
}
open FH, ">", "../data/feeds.json";
print to_json($feeds);
close FH;
