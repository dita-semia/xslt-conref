package org.DitaSemia.Base.AdvancedKeyref.ExtensionFunctions;

import org.DitaSemia.Base.AdvancedKeyref.KeyDef;
import org.DitaSemia.Base.DocumentCaching.BookCacheProvider;

import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.value.SequenceType;

public class GetRootDef extends ExtensionFunctionDefinition {
	
	public static final String LOCAL_NAME	= "getRoot";

	protected final BookCacheProvider bookCacheProvider;
	
	public GetRootDef(BookCacheProvider bookCacheProvider) {
		this.bookCacheProvider	= bookCacheProvider;
	}

	@Override
	public SequenceType[] getArgumentTypes() {
		SequenceType[] sequenceType = {SequenceType.OPTIONAL_ITEM};
		return sequenceType;
	}

	@Override
	public StructuredQName getFunctionQName() {
		return new StructuredQName(KeyDef.NAMESPACE_PREFIX, KeyDef.NAMESPACE_URI, LOCAL_NAME);
	}

	@Override
	public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {
		return SequenceType.OPTIONAL_ELEMENT_NODE;
	}

	@Override
	public ExtensionFunctionCall makeCallExpression() {
		return new GetRootCall(bookCacheProvider);
	}

}
