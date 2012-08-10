import opennlp.tools.postag.POSModel;
import opennlp.tools.postag.POSSample;
import opennlp.tools.postag.POSTaggerME;

import opennlp.tools.sentdetect.SentenceModel;
import opennlp.tools.sentdetect.SentenceDetectorME;
import opennlp.uima.sentdetect.SentenceDetector;

import opennlp.tools.namefind.TokenNameFinderModel;
import opennlp.tools.namefind.NameFinderME;

import opennlp.tools.tokenize.WhitespaceTokenizer;
import opennlp.tools.util.ObjectStream;
import opennlp.tools.util.PlainTextByLineStream;
import opennlp.tools.util.Span;

import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.io.FileInputStream;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;

import org.apache.commons.io.FileUtils;

import com.sun.tools.javac.code.Attribute.Array;

public class pos {
	public static void main(String[] args) throws IOException {

		// Get the directory
		if (args.length < 1) {
			System.out.println("usage: ./pos <directory>");
			System.exit(1);
		}
		String directory = args[0];

		// find all files
		File[] files = new File(directory).listFiles();
/*
		// Load the POS tagger
		POSTaggerME pos = new POSTaggerME(
				new POSModel(
						new FileInputStream("models/en-pos-maxent.bin")));
*/
		// Load the Sentence Detector
		SentenceDetectorME sent = new SentenceDetectorME(
				new SentenceModel(
						new FileInputStream("models/en-sent.bin")));
/*
		// Date finder
		NameFinderME d_finder = new NameFinderME(
				new TokenNameFinderModel(
						new FileInputStream("models/en-ner-date.bin")));
		
		// Location finder
		NameFinderME l_finder = new NameFinderME(
				new TokenNameFinderModel(
						new FileInputStream("models/en-ner-location.bin")));
*/
		// Organization finder
		NameFinderME o_finder = new NameFinderME(
				new TokenNameFinderModel(
						new FileInputStream("models/en-ner-organization.bin")));
/*
		// Person finder
		NameFinderME p_finder = new NameFinderME(
				new TokenNameFinderModel(
						new FileInputStream("models/en-ner-person.bin")));
*/
		// Extract nouns, verbs, and adjectives
		for (File f : files) {
			String content = FileUtils.readFileToString(f);
			String [] sentences = sent.sentDetect(content);
			
			List<String> o_list= new ArrayList<String>();
			List<String> p_list = new ArrayList<String>();
			
			for (String sentence : sentences) {
				String tokens[] = WhitespaceTokenizer.INSTANCE.tokenize(sentence);
				//String[] tags = pos.tag(tokens);
				//Span[] dates = d_finder.find(tokens);
				
				Span[] orgs = o_finder.find(tokens);
				//Span[] peeps = p_finder.find(tokens);

				//POSSample sample = new POSSample(whitespaceTokenizerLine, tags);
				for (Span s : orgs) {
					o_list.add(Arrays.copyOfRange(tokens, s.getStart(), s.getEnd()).toString());
				}
				
				/*
				for (Span s : peeps) {
					p_list.add(Arrays.copyOfRange(tokens, s.getStart(), s.getEnd()).toString());
				}
				*/
				
			}
			if (o_list.size() > 0)
				FileUtils.writeLines(new File(f.getAbsolutePath()+".orgs"), o_list);
			/*
			if (p_list.size() > 0)
				FileUtils.writeLines(new File(f.getAbsolutePath()+".names"), p_list);
			*/
		}
	}
}

