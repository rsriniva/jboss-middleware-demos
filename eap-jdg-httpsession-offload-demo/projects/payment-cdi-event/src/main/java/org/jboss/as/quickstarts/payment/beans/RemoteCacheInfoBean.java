package org.jboss.as.quickstarts.payment.beans;

import java.io.Serializable;
import java.util.Arrays;
import java.util.Map.Entry;
import java.util.Set;
import java.util.logging.Logger;

import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import javax.inject.Named;

import org.infinispan.client.hotrod.RemoteCache;
import org.jboss.as.quickstarts.payment.qualifiers.WebSessionCache;

@Named
@ApplicationScoped
public class RemoteCacheInfoBean implements Serializable{

	private static final long serialVersionUID = 1L;
	
	@Inject
	private Logger log;

    @Inject
    @WebSessionCache
    private RemoteCache remoteCache;

    public String getCacheInfo(){
		StringBuffer sb = new StringBuffer();
		
		sb.append("<pre>");
		sb.append(String.format("Cache Name: %10s \n", remoteCache.getName()));
		sb.append(String.format("Cache Size: %10s\n", remoteCache.size()));
		
		sb.append("\n---\n");
		sb.append("Cache Stats\n");
		for (Entry<String, String> entry : remoteCache.stats().getStatsMap().entrySet()){
//			log.info("Entry key [" + entry.getKey()  + "]: value => " + entry.getValue());
			sb.append(entry.getKey()  + ": " + entry.getValue() + "\n");
		}
		sb.append("---\n");
		
		
		// For some reason (I don't figure out yet :-\) thi remote cache does not returns it's entries
		// I suspect this is because the remote caches is being used just as a remote store for the local embedded infinispan API
		/*
		for (Entry<Object, Object> entry : remoteCache.entrySet()){
			count++;
			log.info("Entry key [" + entry.getKey()  + "]: value => " + entry.getValue());
			sb.append("Entry key [" + entry.getKey()  + "]: value => " + entry.getValue() + "\n");
			
			if (count > 10)
				break;
		}
		
		for (Entry<Object, Object> entry : remoteCache.getBulk().entrySet()){
			log.info("Entry key [" + entry.getKey()  + "]: value => " + entry.getValue());
			sb.append("Entry key [" + entry.getKey()  + "]: value => " + entry.getValue() + "\n");
		}
		*/
		
		sb.append("</pre>");
		
		return sb.toString();
	}
	
}
