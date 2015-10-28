/*
 * This file is part of the DITA-SEMIA project (www.dita-semia.org).
 * See the accompanying LICENSE file for applicable licenses.
 */

package org.DitaSemia.XsltConref;

import org.DitaSemia.JavaBase.AuthorNodeWrapper;
import org.DitaSemia.JavaBase.XslTransformerCache;
import org.apache.log4j.Logger;

import ro.sync.ecss.extensions.api.ArgumentDescriptor;
import ro.sync.ecss.extensions.api.ArgumentsMap;
import ro.sync.ecss.extensions.api.AuthorAccess;
import ro.sync.ecss.extensions.api.AuthorOperation;
import ro.sync.ecss.extensions.api.AuthorOperationException;
import ro.sync.ecss.extensions.api.node.AuthorNode;

public class RefreshReference implements AuthorOperation {

	private static final Logger logger = Logger.getLogger(RefreshReference.class.getName());

	@Override
	public String getDescription() {
		return "Refreshs the reference of an XSLT-Conref element.";
	}

	@Override
	public void doOperation(AuthorAccess authorAccess, ArgumentsMap argumentsMap) throws IllegalArgumentException, AuthorOperationException {
		try {
			final int 			caretOffset = authorAccess.getEditorAccess().getCaretOffset();
			final AuthorNode	nodeAtCaret = authorAccess.getDocumentController().getNodeAtOffset(caretOffset);
			
			final XsltConref 	xsltConref	= XsltConref.fromNode(new AuthorNodeWrapper(nodeAtCaret, authorAccess));
			
			if (xsltConref != null) {
				// ensure the script will be recompiled.
				XslTransformerCache.getInstance().removeFromCache(xsltConref.getScriptUrl());
			}
			authorAccess.getDocumentController().refreshNodeReferences(nodeAtCaret);
		} catch (Exception e) {
			logger.error(e, e);
		}
	}

	@Override
	public ArgumentDescriptor[] getArguments() {
		return null;
	}

}