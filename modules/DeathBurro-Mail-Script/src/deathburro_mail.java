import java.io.PrintWriter;
import java.io.StringWriter;

import java.text.DateFormat;

import java.util.HashMap;
import java.util.Properties;

import javax.mail.Session;
import javax.mail.Store;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.Part;
import javax.mail.Multipart;
import javax.mail.Address;
import javax.mail.Flags;
import javax.mail.Flags.Flag;
import javax.mail.search.SearchTerm;
import javax.mail.search.FlagTerm;
import javax.mail.search.SubjectTerm;
import javax.mail.search.FromStringTerm;
import javax.mail.search.AndTerm;
import javax.mail.search.OrTerm;


public class deathburro_mail {
	public static String VERSION = "1.0.0.0";
	
	public static String getHelpInfo() {
		String help = "deathburro_mail.java " + VERSION + "\n";
		help += "\n";
		help += "Authored by Kristoffer Smith\n";
		help += "Copyright (c) Kristoffer Smith 2011\n";
		help += "http://devbutton.com\n";
		help += "\n";		
		help += "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n";
		help += "\n";
		help += "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n";
		help += "\n";
		help += "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n";		
		help += "\n";
		help += "This is a simple app to fetch mail based on criteria passed in as arguments. It returns the fetched mail in a custom xml wrapper to stdout.\n";
		help += "It was designed to be a modular component of the DeathBurro application (a custom app for the Chumby One). See the DeathBurro DEV MANUAL for full documentation on arguments and return.\n";
		help += "\n";
		help += "Required args: -protocol:[IMAP or POP3] -server:[hostname or IP] -port:[number] -user:[username] -pwd:[password]\n";
		help += "Optional args: -ssl:[0 or 1] -folders:[folder1|folder2] -subjects:[containsphrase1|containsphrase2] -froms:[containsphrase1|containsphrase2] -bodylen:[number] -subjlen:[number] -max:[number]\n";
		help += "\n";
		help += "NOTE: This app marks msgs READ as they are retrieved!";		
		return help;
	}
	
	public static void main(String[] args) {
		System.out.println("<MailScriptOutput>");

		try {			
			//--- defaults
			
			boolean DEFAULT_GET_UNREAD_ONLY = true;
			String DEFAULT_FOLDER = "INBOX";
			int DEFAULT_MAX_BODY_LENGTH = 0;
			int DEFAULT_MAX_SUBJECT_LENGTH = 0;
			int DEFAULT_MAX_MSGS = 0;
			
			//--- configuration based on args
			
			HashMap<String, String> cfg = new HashMap<String, String>();
			
			if (args == null || args.length <= 0) throw new IllegalArgumentException("No arguments found!"); 
			
			//parse args to hashmap (expected in format "-arg:value")
			for (int i = 0; i < args.length; i++) {				
				if (args[i].indexOf("-") == 0) args[i] = args[i].substring(1);
				
				//help flag found
				if (args[i].trim().toLowerCase().equals("?") || args[i].trim().toLowerCase().equals("h") || args[i].trim().toLowerCase().equals("help")) {
					System.out.println(getHelpInfo());
					System.out.println("</MailScriptOutput>");
					System.exit(0);					
				}	
				
				String[] param = args[i].split(":");					
				if (param.length != 2) throw new IllegalArgumentException("Invalid argument format!");
								
				cfg.put(param[0].trim().toLowerCase(), param[1].trim());
			}
			
			//default the optional args
			if (cfg.get("max") != null) DEFAULT_MAX_MSGS = Integer.parseInt(cfg.get("bodylen"));			
			
			if (cfg.get("bodylen") != null) DEFAULT_MAX_BODY_LENGTH = Integer.parseInt(cfg.get("bodylen"));
		
			if (cfg.get("subjlen") != null) DEFAULT_MAX_SUBJECT_LENGTH = Integer.parseInt(cfg.get("subjlen"));			

			Boolean ssl = false;
			if (cfg.get("ssl") != null && cfg.get("ssl").equals("1")) ssl = true;

			if (cfg.get("folders") == null || cfg.get("folders").isEmpty() || cfg.get("folders").equals("*")) cfg.put("folders", DEFAULT_FOLDER);
			String[] folderlist = cfg.get("folders").split("\\|");
			
			String[] subjectlist;
			if (cfg.get("subjects") != null && !cfg.get("subjects").equals("*")) subjectlist = cfg.get("subjects").split("\\|");
			else subjectlist = new String[0];

			String[] fromlist;
			if (cfg.get("froms") != null && !cfg.get("froms").equals("*")) fromlist = cfg.get("froms").split("\\|");
			else fromlist = new String[0];

			//setup the mail props object
			Properties props = (Properties)System.getProperties().clone();
			
			if (cfg.get("protocol").equalsIgnoreCase("IMAP")) {								
				if (ssl) {
					props.setProperty("mail.store.protocol", "imaps");
					props.setProperty("mail.imaps.socketFactory.port", cfg.get("port"));
					props.setProperty("mail.imaps.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
				}
				else {
					props.setProperty("mail.store.protocol", "imap");
					props.setProperty("mail.imap.socketFactory.port", cfg.get("port"));
				}
			} else {
				//everything to do with filter/search/etc is based on IMAP
				throw new Error("Only IMAP protocol currently supported!");
				
				//todo: modify to work with POP3
			}
			
			
			//--- connect to mail host
			
			Session session = Session.getDefaultInstance(props, null);
			Store store = session.getStore(props.getProperty("mail.store.protocol"));
			store.connect(cfg.get("server"), cfg.get("user"), cfg.get("pwd"));

			
			//--- get mail for each folder
			
			for (int f = 0; f < folderlist.length; f++) {
				//create complex search to filter based on config
				
				int flagCount = 0;
				if (DEFAULT_GET_UNREAD_ONLY) flagCount = 1; //currently only one flag possible, started code in a way to work with more 
				SearchTerm[] searchFlags = new FlagTerm[flagCount];
				if (DEFAULT_GET_UNREAD_ONLY) {
					searchFlags[0] = new FlagTerm(new Flags(Flag.SEEN), false);	
				}
				SearchTerm searchAllFlags = new OrTerm(searchFlags);

				SearchTerm[] searchSubjs = new SubjectTerm[subjectlist.length];
				for (int s = 0; s < searchSubjs.length; s++) {
					searchSubjs[s] = new SubjectTerm(subjectlist[s]);
				}
				SearchTerm searchAllSubjs = new OrTerm(searchSubjs);
				
				SearchTerm[] searchFroms = new FromStringTerm[fromlist.length];
				for (int s = 0; s < searchFroms.length; s++) {
					searchFroms[s] = new FromStringTerm(fromlist[s]);
				}
				SearchTerm searchAllFroms = new OrTerm(searchFroms);
				
				//create array of all the OR group searches to make a big AND search
				int searchesAllCount = 0;
				if (searchFlags.length > 0) searchesAllCount++;
				if (searchSubjs.length > 0) searchesAllCount++;
				if (searchFroms.length > 0) searchesAllCount++;
				SearchTerm[] searchesAll = new SearchTerm[searchesAllCount];				
				searchesAllCount = 0;
				if (searchFlags.length > 0) {
					searchesAll[searchesAllCount] = searchAllFlags;
					searchesAllCount++;
				}
				if (searchSubjs.length > 0) {
					searchesAll[searchesAllCount] = searchAllSubjs;
					searchesAllCount++;
				}				
				if (searchFroms.length > 0) {
					searchesAll[searchesAllCount] = searchAllFroms;
					searchesAllCount++;
				}

				//create the final big AND search
				SearchTerm searchesFinal = new AndTerm(searchesAll);

				//open folder
				Folder folder = store.getFolder(folderlist[f]);
				folder.open(Folder.READ_WRITE);
				
				//get msgs based on search
				Message[] messages;
				if (searchesAll.length > 0) messages = folder.search(searchesFinal);
				else messages = folder.getMessages();
				
				//ouput msgs
				System.out.println("<ScriptMail>");
				try {
					for (int m = 0; m < messages.length; m++) {
						//msg node start
						String msg = "";
						
						//subject
						String msgSubject = messages[m].getSubject();
						if (msgSubject != null && msgSubject.length() > DEFAULT_MAX_SUBJECT_LENGTH) {
							msgSubject = msgSubject.substring(0, DEFAULT_MAX_SUBJECT_LENGTH - 1).trim();
							msgSubject += "... (truncated)";
						} else if (msgSubject != null) {
							msgSubject = msgSubject.trim();
						}
						if (msgSubject != null && !msgSubject.isEmpty()) msg += "<MailItemSubject><![CDATA[" + msgSubject + "]]></MailItemSubject>";
				
						//date
						java.util.Date msgWhen = messages[m].getReceivedDate();
						if (msgWhen != null) {
							DateFormat whenFormat = DateFormat.getDateTimeInstance(0, 3);
							msg += "<MailItemDate>" + whenFormat.format(msgWhen) + "</MailItemDate>";				
						}
						
						//senders
						String msgSender = "";
						Address[] msgFroms = messages[m].getFrom();
						if (msgFroms != null && msgFroms.length > 0) {
							for (int a = 0; a < msgFroms.length; a++) {							
								msgSender += msgFroms[a].toString().trim() + ", ";
							}
							msgSender = msgSender.substring(0, msgSender.length() - 2);
						}					
						if (!msgSender.isEmpty()) msg += "<MailItemSender><![CDATA[" + msgSender + "]]></MailItemSender>";
						
						//body
						String msgBody = getMsgBody(messages[m].getContent(), DEFAULT_MAX_BODY_LENGTH);
						if (msgBody != null && !msgBody.isEmpty()) msg += "<MailItemBody><![CDATA[" + msgBody + "]]></MailItemBody>";
						
						//output msg node
						System.out.println("<ScriptMailItem>" + msg + "</ScriptMailItem>\n");
						
						//mark this msg read on the server
						messages[m].setFlag(Flag.SEEN, true);
						
						//limit number downloaded per run of this script so that return string is not too big for Flash movie
						if (m >= DEFAULT_MAX_MSGS) break;
					}
				} catch (Exception e) {
					throw e;
				} finally {
					System.out.println("</ScriptMail>");	
				}
				
				if (folder.isOpen()) folder.close(false);
			}
			
			//finished successfully			
			if (store.isConnected()) store.close();			
			System.out.println("<ScriptStatus>COMPLETE!</ScriptStatus>");
			System.out.println("</MailScriptOutput>");
			System.exit(0);
		} catch (IllegalArgumentException e) {
			//missing/invalid args

			System.out.println("<ScriptError><![CDATA[" + e.getClass() + ": " + e.getMessage() + "\nUse -? for help.]]></ScriptError>");
			System.out.println("</MailScriptOutput>");
			System.exit(1);			
		} catch (Exception e) {
			//had an oops
			
			StringWriter sw = new StringWriter();
		    PrintWriter pw = new PrintWriter(sw);
		    e.printStackTrace(pw);
			
			System.out.println("<ScriptError><![CDATA[" + sw.toString() + "]]></ScriptError>");
			System.out.println("</MailScriptOutput>");
			System.exit(1);
		}
	}
	
	//get the text from a plain/text message, or recurses into a multi-part message to get any plain/text parts
	//add warnings for any parts not included in output
	//mailContent can be a String, Part (inc BodyPart), or MultiPart (inc MimeMultiPart)
	public static String getMsgBody(Object mailContent, int maxBodyLen) throws Exception {
		String retval = "";
		
		if (mailContent != null && mailContent instanceof String) {
			if (((String)mailContent).length() > maxBodyLen) {
				retval += ((String)mailContent).substring(0, maxBodyLen - 1).trim();
				retval += "... (truncated)";
			} else {
				retval += ((String)mailContent).trim();
			}			
		} else if (mailContent != null && mailContent instanceof Part) {
			String msgType = ((Part)mailContent).getContentType();
			if (msgType != null && msgType.toLowerCase().indexOf("text/plain") == 0) {
				retval += getMsgBody(((Part)mailContent).getContent(), maxBodyLen);
			} else {
				retval += "\n\n[multipart not included: " + msgType + "]";
			}
		} else if (mailContent != null && mailContent instanceof Multipart) {
			 for (int b = 0; b < ((Multipart)mailContent).getCount(); b++) {
				 Part body = ((Multipart)mailContent).getBodyPart(b);
				 retval += getMsgBody(body, maxBodyLen);
			 }
		} else {
			retval += "\n\n[mime-type not supported: " + mailContent.toString() + "]";
		}
		
		//todo: eventually want to handle file attachments (only if is a donkeymsg1-0 spec "cmd" msg)
		
		return retval;
	}
}