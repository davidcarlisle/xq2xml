import net.sf.saxon.Err;
import net.sf.saxon.TransformerFactoryImpl;
import net.sf.saxon.Controller;
import net.sf.saxon.Configuration;
import net.sf.saxon.style.StandardNames;
import net.sf.saxon.tinytree.TinyBuilder;
import net.sf.saxon.charcode.UnicodeCharacterSet;
import net.sf.saxon.expr.*;
import net.sf.saxon.om.*;
import net.sf.saxon.sort.GlobalOrderComparer;
import net.sf.saxon.trace.Location;
import net.sf.saxon.trans.DynamicError;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.type.SchemaType;
import net.sf.saxon.type.Type;
import net.sf.saxon.value.*;

import javax.xml.transform.Templates;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.io.ByteArrayInputStream;
import java.io.InputStreamReader;
import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.om.NodeInfo;
import net.sf.saxon.style.StandardNames;
import net.sf.saxon.trace.InstructionInfo;
import net.sf.saxon.trace.InstructionInfoProvider;
import net.sf.saxon.trace.Location;
import net.sf.saxon.trans.DynamicError;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.type.ValidationException;
import org.xml.sax.SAXException;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.SourceLocator;
import javax.xml.transform.TransformerException;
import javax.xml.transform.dom.DOMLocator;
import java.io.PrintStream;


public class trans2 {

    public static Object compileStylesheet(XPathContext context, DocumentInfo doc) {
        try {
            TransformerFactoryImpl factory = new TransformerFactoryImpl(context.getController().getConfiguration());
            return factory.newTemplates(doc);
        } catch (TransformerException e) {
	    String eres = "error";

	    if (e instanceof XPathException) {
	    eres = ((XPathException)e).getErrorCodeLocalPart();
    } else if (e.getException() instanceof XPathException) {
            eres = ((XPathException)e.getException()).getErrorCodeLocalPart();
        } else {
	     eres=e.getMessage() ;
    };
            eres = "err:" + eres;
	    return eres;
        }
	catch (Exception e){
	    String eres = null;
	    if (e instanceof XPathException) {
	    eres = ((XPathException)e).getErrorCodeLocalPart();
	    } else {
	     eres=e.getMessage() ;
    };
            eres = "err:" + eres;
	    return eres;

	}
    }

    public static Object transform(XPathContext context, Templates templates, NodeInfo source) {
        try {
            Transformer transformer = templates.newTransformer();
            TinyBuilder builder = new TinyBuilder();
            builder.setPipelineConfiguration(context.getController().makePipelineConfiguration());
            transformer.transform(source, builder);
            return (DocumentInfo)builder.getCurrentRoot();
        } catch (TransformerException e) {
	    String eres = "error";

	    if (e instanceof XPathException) {
	    eres = ((XPathException)e).getErrorCodeLocalPart();
    } else if (e.getException() instanceof XPathException) {
            eres = ((XPathException)e.getException()).getErrorCodeLocalPart();
        } else {
	     eres=e.getMessage() ;
    };
            eres = "err:" + eres;
	    return eres;
        }
	catch (Exception e){
	    String eres = null;
	    if (e instanceof XPathException) {
	    eres = ((XPathException)e).getErrorCodeLocalPart();
	    } else {
	     eres=e.getMessage() ;
    };
            eres = "err:" + eres;
	    return eres;

	}
    }

}





//
// The contents of this file are subject to the Mozilla Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied.
// See the License for the specific language governing rights and limitations under the License.
//
// The Original Code is: all this file.
//
// The Initial Developer of the Original Code is Michael H. Kay.
//
// Portions created by (your name) are Copyright (C) (your legal entity). All Rights Reserved.
//
// Contributor(s): none.
//
