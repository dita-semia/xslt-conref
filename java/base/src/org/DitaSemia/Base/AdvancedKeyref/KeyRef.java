package org.DitaSemia.Base.AdvancedKeyref;

import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.Stack;
import java.util.StringTokenizer;

import net.sf.saxon.trans.XPathException;

import org.DitaSemia.Base.NodeWrapper;
import org.DitaSemia.Base.XPathNotAvaliableException;
import org.DitaSemia.Base.DocumentCaching.BookCache;
import org.apache.log4j.Logger;

public class KeyRef implements KeyRefInterface {

	private static final Logger logger = Logger.getLogger(KeyRef.class.getName());
	
	
	public 	static final String NAMESPACE_URI 			= "http://www.dita-semia.org/advanced-keyref";
	public 	static final String NAMESPACE_PREFIX 		= "akr"; 
	public 	static final String ATTR_REF				= "ref";
	public 	static final String ATTR_OUTPUTCLASS		= "outputclass";
	
	public  static final String OC_KEY					= "key";
	public  static final String OC_KEY_NAME_BRACED		= "key-name-braced";
	public  static final String OC_KEY_DASH_NAME		= "key-dash-name";
	public  static final String OC_NAME					= "name";
	public  static final String OC_KEY_COLON_NAME		= "key-colon-name";
	public 	static final String OC_SVG 					= "svg";
	
	public  static final String LEFT_QUOTE				= "\u201C";
	public  static final String RIGHT_QUOTE				= "\u201D";
	
	private static final String ATTR_TYPE_FILTER		= "type";
	private static final String ATTR_NAMESPACE_FILTER 	= "namespace";
	private static final String ATTR_FIXED_PATH_LEN 	= "path-len";

	private static final String	OC_FIXED_MARKER			= "!";
	
	private static final String	UNKNOWN_NAME			= "???";
	
	private final static String COLON 					= ":";
	private final static String PERIOD 					= ".";
	private final static String SLASH 					= "/";
	private final static String BACKSLASH 				= "\\";
	
	private final static int 	NO_STATE 				= 0;
	private final static int 	STRING					= 1;
	private final static int	ESCAPE					= 2;
	
	

	private NodeWrapper 	node;
	private boolean			isInitDone		= false;
	private String 			type			= null;
	private String 			key				= null;
	private List<String> 	namespace		= null;
	
	public static KeyRef fromNode(NodeWrapper node) {
		final String refAttr = node.getAttribute(ATTR_REF, NAMESPACE_URI);
		if (refAttr != null) {
			return new KeyRef(node);	
		} else {
			return null;
		}
	}
	
	public KeyRef(NodeWrapper node) {
		this.node 	= node;	
	}
	
	@Override
	public String getRefString() {
		return node.getAttribute(ATTR_REF, NAMESPACE_URI);
	}
	
	public DisplaySuffix getDisplaySuffix(BookCache cache, boolean showUnknownName) {
		return getDisplaySuffix(getMatchingKeyDef(cache), showUnknownName);
	}
	
	public DisplaySuffix getDisplaySuffix(KeyDefInterface keyDef, boolean showUnknownName) {
		String key		= null;
		String name 	= (showUnknownName) ? UNKNOWN_NAME : null;
		if (keyDef != null) {
			key		= keyDef.getKey();
			name 	= keyDef.getName();
		}
		String keySuffix 	= "";
		String nameSuffix 	= "";
		if ((name != null) && (!name.isEmpty())) {
			final boolean 	isKeyEmpty 	= ((key == null) || (key.isEmpty()));
			final String 	outputclass = getOutputclass();
			if (outputclass.equals(OC_KEY_DASH_NAME)) {
				if (!isKeyEmpty) {
					keySuffix = " \u2013 ";
				}
				nameSuffix = name;
			} else if (outputclass.equals(OC_NAME)) {
				nameSuffix = name;
			} else if (outputclass.equals(OC_KEY_COLON_NAME)) {
				if (!isKeyEmpty) {
					keySuffix = ": ";
				}
				nameSuffix = name;
			} else {
				// for outputclass "key" hiding the name will be done by css - but not in every case so provide it here.
				nameSuffix = " (" + name + ")";
			}
		}
		//logger.info("outputclass: " + getOutputclass() + ", keySuffix: " + keySuffix + ", nameSuffix:" + nameSuffix);
		return new DisplaySuffix(keySuffix, nameSuffix);
	}
	
	public KeyDefInterface getMatchingKeyDef(BookCache cache) {
		return (cache != null ? cache.getExactMatch(this) : null);
	}
	
	@Override
	public URL getBaseUrl() {
		return node.getBaseUrl();
	}

	@Override
	public String getText() {
		return node.getTextContent();
	}
	
//	public List<String> getRefStringList() {
//		String 			refString 	= getRefString();
//		List<String> 	ref 		= new ArrayList<>();
//		Stack<String> 	tokenStack 	= new Stack<>();
//		Stack<Integer>	stateStack 	= new Stack<>();		
//		StringTokenizer tok 		= new StringTokenizer(refString, ":./\\", true);
//		
//		
//	}
	
	private void init() {
		isInitDone = true;
		final String 	refString 	= getRefString();
		List<String> 	ref			= new ArrayList<>();
		Stack<String> 	tokenStack 	= new Stack<>();
		Stack<Integer>	stateStack 	= new Stack<>();		
		StringTokenizer tok 		= new StringTokenizer(refString, ":./\\", true);
		
		stateStack.push(NO_STATE);
		while (tok.hasMoreTokens()) {
			String token = tok.nextToken();
			if (token.equals(COLON) || token.equals(PERIOD) || token.equals(SLASH)) {
				addToken(tokenStack, stateStack, token);
			} else if (token.equals(BACKSLASH)) {
				stateStack.push(ESCAPE);
			} else {
				if (stateStack.peek() == STRING) {
					String str = tokenStack.pop();
					str = str + token;
					tokenStack.push(str);
				} else {
					tokenStack.push(token);
					stateStack.push(STRING);
				}
			}
		}
		ref.addAll(tokenStack);
		String[] list = ref.toArray(new String[ref.size()]);
		
		if (list.length > 0) {
			type = list[0];
			if (list.length > 1) {
				key = list[list.length -1];
				if (list.length > 2) {
					namespace = new LinkedList<>();
					for (int i = 1; i < list.length - 1; ++i) {
						namespace.add(list[i]);
					}
				}
			}
		}
		
		if ((type == null) || (type.isEmpty())) {
			final Set<String> typeFilter = getTypeFilter();
			if ((typeFilter != null) && (typeFilter.size() == 1)) {
				type = typeFilter.iterator().next();
			}
		}
		//logger.info("ref:       " + ref);
		//logger.info("type:      " + type);
		//logger.info("key:       " + key);
		//logger.info("namespace: " + ((namespace == null) ? null : String.join(PATH_DELIMITER, namespace)));
	}

	private static void addToken(Stack<String> tokenStack, Stack<Integer> stateStack, String token) {
		if (stateStack.peek() == ESCAPE) {
			stateStack.pop();
			if (stateStack.peek() == STRING) {
				String str = tokenStack.pop();
				str = str + "\\" + token;
				tokenStack.push(str);
			} else {
				stateStack.push(STRING);
				tokenStack.push("\\" + token);
			}
		} else {
			stateStack.push(NO_STATE);
		}
	}
	
	@Override
	public String getKey() {
		if (!isInitDone) {
			init();
		}
		return key;
	}

	@Override
	public String getType() {
		if (!isInitDone) {
			init();
		}
		return type;
	}

	@Override
	public String getNamespace() {
		if (!isInitDone) {
			init();
		}
		return ((namespace == null) ? null : String.join(PATH_DELIMITER, namespace));
	}

	@Override
	public List<String> getNamespaceList() {
		if (!isInitDone) {
			init();
		}
		return namespace;
	}

	@Override
	public Set<String> getTypeFilter() {
		String typeFilter = node.getAttribute(ATTR_TYPE_FILTER, NAMESPACE_URI);
		if ((typeFilter != null) && (!typeFilter.isEmpty())) {
			String[] 	typeArray	= typeFilter.split("[\\s]+");
			Set<String> typeSet	= new HashSet<>(Arrays.asList(typeArray));
			return typeSet;
		} else {
			return null;
		}
	}

	@Override
	public List<String> getNamespaceFilter() {
		try {
			final String 		namespaceFilterXPath 	= node.getAttribute(ATTR_NAMESPACE_FILTER, NAMESPACE_URI);
			if ((namespaceFilterXPath == null) || (namespaceFilterXPath.isEmpty())) {
				return null;
			} else {
//				logger.info("getNamespaceFilter: " + namespaceFilterXPath);
//				logger.info("ergebnis: " + node.evaluateXPathToStringList(namespaceFilterXPath));
				return node.evaluateXPathToStringList(namespaceFilterXPath);
			}
		} catch (XPathException | XPathNotAvaliableException e) {
			logger.error(e, e);
			return null;
		}
	}

	@Override
	public int getFixedPathLen() {
		String pathlen = node.getAttribute(ATTR_FIXED_PATH_LEN, NAMESPACE_URI); 
		if (pathlen == null) {
			return 0;
		} else {
			try {
				return Integer.parseInt(pathlen);
			} catch (NumberFormatException e) {
				//TODO
//				throw new XPathException("Invalid argument for path-len attribute ('" + pathlen + "').");
				return 0;
			}
		}
		
	}

//	@Override
//	public boolean isNamespaceFixed() {
//		// TODO Auto-generated method stub
//		return false;
//	}

	@Override
	public int getPathLen() {
		if (!isInitDone) {
			init();
		}
		int fixedPathLen = getFixedPathLen();
		if (fixedPathLen > 0) {
			return fixedPathLen;
		} else if (fixedPathLen == -1) {
			return namespace.size() + 1;
		} else {
			String path = getText();
			int startIndex = -1;
			for (String s : namespace) {
				if (path.startsWith(s)) {
					startIndex = namespace.indexOf(s);
				}
			}
			if (startIndex > -1) {
				return namespace.size() - startIndex + 1;
			} else {
				//only the key, no namespace elements
				return 1;
			}
		}
	}

	@Override
	public NodeWrapper getNode() {
		return node;
	}

//	@Override
//	public String getPath() {
//		// TODO Auto-generated method stub
//		logger.info("getPath(): type:namespace.key : " + getType() + ":" + getNamespace() + "." + getKey());
//		return getNamespace() + "." + getKey();
//	}

	@Override
	public String toString() {
		final StringBuilder stringBuilder = new StringBuilder();
		stringBuilder.append("key = '");
		stringBuilder.append(getKey());
		stringBuilder.append("', type = '");  
		stringBuilder.append(getType());
		stringBuilder.append("' , namespace = '");
		stringBuilder.append(getNamespace());
		stringBuilder.append("'");
		final Set<String> typeFilter = getTypeFilter();
		if (typeFilter != null) {
			stringBuilder.append(", typeFilter: [");
			stringBuilder.append(String.join(", ", typeFilter));
			stringBuilder.append("]");
		}
		final List<String> namespaceFilter = getNamespaceFilter();
		if (namespaceFilter != null) {
			stringBuilder.append(", namespaceFilter: [");
			stringBuilder.append(String.join(", ", namespaceFilter));
			stringBuilder.append("]");
		}
		return stringBuilder.toString();
	}

	@Override
	public String getOutputclass() {
		final String outputclass = node.getAttribute(ATTR_OUTPUTCLASS, null);
		if ((outputclass == null) || (outputclass.isEmpty())) {
			return OC_KEY_NAME_BRACED;
		} else if (isOutputclassFixed()) {
			return outputclass.substring(0, outputclass.length()-1);
		} else {
			return outputclass;
		}
	}

	@Override
	public boolean isOutputclassFixed() {
		final String outputclass = node.getAttribute(ATTR_OUTPUTCLASS, null);
		return ((outputclass == null) || (outputclass.endsWith(OC_FIXED_MARKER)));
	}

	public static boolean matchesNamespaceFilter(List<String> namespaceFilter, List<String> namespace) {
		//logger.info("matchesNamespaceFilter(" + String.join("/", namespaceFilter) + ", " + String.join("/", namespace));
		if ((namespace != null && !namespace.isEmpty()) && (namespaceFilter != null && !namespaceFilter.isEmpty())) {
			int nsFilterLength 	= namespaceFilter.size();
			int nsLength		= namespace.size();
			if (namespaceFilter.get(namespaceFilter.size() - 1).equals(KeyDef.ANY_NAMESPACE)) {
				//any subsidiary elements are allowed
				if (nsFilterLength > nsLength + 1) {
					//logger.info("  -> " + false + " (1)");
					return false;
				}
				for (int i = 0; i < nsFilterLength; i++) {
					if (!namespaceFilter.get(i).equals(KeyDef.ANY_NAMESPACE) && !namespaceFilter.get(i).equals(namespace.get(i))) {
						//logger.info("  -> " + false + " (2)");
						return false;
					}
				}
				//logger.info("  -> " + true + " (3)");
				return true;
			} else {
				//exact match
				for (int i = 0; i < nsFilterLength; i++) {
					if ((i < nsLength) && (!namespaceFilter.get(i).equals(namespace.get(i)))) {
						//logger.info("  -> " + false + " (4)");
						return false;
					}
				}
				//logger.info("  -> " + false + " (5)");
				return true;
			}
		} else if ((namespace == null || namespace.isEmpty()) && (namespaceFilter != null && !namespaceFilter.isEmpty())) {
			//logger.info("  -> " + false + " (6)");
			return false;
		} else {
			//logger.info("  -> " + false + " (7)");
			return true;
		}
	}
	
	public static boolean matchesTypeFilter(Set<String> typeFilter, String type) {
		return (typeFilter == null) || (typeFilter.contains(type));
	}
	
	public static class DisplaySuffix {
		public final String keySuffix;
		public final String nameSuffix;
		
		DisplaySuffix(String keySuffix, String nameSuffix) {
			this.keySuffix 	= keySuffix;
			this.nameSuffix = nameSuffix;
		}
		
		@Override
		public String toString() {
			return keySuffix + nameSuffix;
		}
	}
}
