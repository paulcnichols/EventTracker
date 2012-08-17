delimiter $$

CREATE DATABASE `ucsd` /*!40100 DEFAULT CHARACTER SET latin1 */$$

CREATE TABLE `article` (
  `article_id` int(11) NOT NULL AUTO_INCREMENT,
  `feed` int(11) NOT NULL,
  `timestamp` int(11) NOT NULL,
  PRIMARY KEY (`article_id`),
  KEY `FEED` (`feed`,`timestamp`),
  KEY `TIMESTAMP` (`timestamp`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1$$


CREATE TABLE `article_term` (
  `article_id` int(11) NOT NULL,
  `term_id` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `tf` float NOT NULL,
  `idf` float NOT NULL,
  KEY `ARTICLE_TERM` (`article_id`,`term_id`),
  KEY `TERM` (`term_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1$$

CREATE TABLE `feed` (
  `feed_id` int(11) NOT NULL,
  `feed_name` text,
  PRIMARY KEY (`feed_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1$$

CREATE TABLE `term` (
  `term_id` int(11) NOT NULL AUTO_INCREMENT,
  `term` text NOT NULL,
  PRIMARY KEY (`term_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1$$

