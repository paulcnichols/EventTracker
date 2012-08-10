var FeedParser = require('feedparser'), 
    parser = new FeedParser(),
    fs = require('fs'),
    request = require('request'),
    articles = [];

parser.on('article', function (article){
    articles.push(article);
});
parser.on('end', function() {
    console.log(JSON.stringify(articles));
});

// You can give a local file path to parseFile()
//parser.parseFile('./feed');

// For libxml compatibility, you can also give a URL to parseFile()
//parser.parseFile('http://cyber.law.harvard.edu/rss/examples/rss2sample.xml');

// Or, you can give that URL to parseUrl()
parser.parseUrl('http://feeds.bbci.co.uk/news/rss.xml');

// But you should probably be using conditional GETs and passing the results to
// parseString() or piping it right into the stream, if possible

//var reqObj = {'uri': 'http://cyber.law.harvard.edu/rss/examples/rss2sample.xml',
//              'headers': {'If-Modified-Since' : <your cached 'lastModified' value>,
//                          'If-None-Match' : <your cached 'etag' value>}};

// parseString()
//request(reqObj, function (err, response, body){
//    parser.parseString(body);
//});

// Stream piping -- very sexy
//request(reqObj).pipe(parser.stream);

// Using the stream interface with a file (or string)
// A good alternative to parseFile() or parseString() when you have a large local file
//parser.parseStream(fs.createReadStream('./feed'));
// Or
//fs.createReadStream('./feed').pipe(parser.stream);
