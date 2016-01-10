package org.jboss.as.quickstarts.payment.beans;

import java.io.Serializable;
import java.util.Date;

import javax.enterprise.context.SessionScoped;
import javax.inject.Named;

import org.omnifaces.util.Faces;

@Named
@SessionScoped
public class WebSessionInfoBean implements Serializable{

	private static final long serialVersionUID = 1L;

	public String getWebSessionInfo(){
		StringBuffer sb = new StringBuffer();
		
		sb.append("<pre>");
		sb.append(String.format("<b>Session Id: %10s \n", Faces.getSessionId()) + "</b>");
		sb.append(String.format("Session Creation Time: %10s\n", new Date(Faces.getSessionCreationTime())));
		sb.append(String.format("Session Last Accessed Time: %10s\n", new Date(Faces.getSessionLastAccessedTime())));
		sb.append("\n---\n");
		sb.append(String.format("Node Name: <b>%10s</b> \n", System.getProperty("jboss.node.name","not specified")));
		sb.append(String.format("Server Addr: %10s \n", Faces.getRemoteAddr()));
		sb.append(String.format("Server Info: %10s \n", Faces.getServerInfo()));
		sb.append("</pre>");
		
		return sb.toString();
	}
	
}
