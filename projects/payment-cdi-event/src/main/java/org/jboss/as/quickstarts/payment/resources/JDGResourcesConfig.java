/*
 * JBoss, Home of Professional Open Source
 * Copyright 2011 Red Hat Inc. and/or its affiliates and other
 * contributors as indicated by the @author tags. All rights reserved.
 * See the copyright.txt in the distribution for a full listing of
 * individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */
package org.jboss.as.quickstarts.payment.resources;

import java.util.logging.Logger;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.inject.Disposes;
import javax.enterprise.inject.Produces;
import javax.inject.Inject;

import org.infinispan.client.hotrod.RemoteCache;
import org.infinispan.client.hotrod.RemoteCacheManager;
import org.jboss.as.quickstarts.payment.qualifiers.WebSessionCache;

/**
 * This is the configuration class for DG.
 */
public class JDGResourcesConfig {

	@Inject
	private Logger log;

	final String jdgNode1Addr;
	final int jdgNode1Port;
	final String jdgNode2Addr;
	final int jdgNode2Port;
	
	public JDGResourcesConfig(){
		jdgNode1Addr = System.getProperty("jdg.remoting.hothod.node1.addr", "127.0.0.1");
		jdgNode1Port = Integer.valueOf(System.getProperty("jdg.remoting.hothod.node1.port", "11122"));
		jdgNode2Addr = System.getProperty("jdg.remoting.hothod.node2.addr", "127.0.0.1");
		jdgNode2Port = Integer.valueOf(System.getProperty("jdg.remoting.hothod.node1.port", "11122"));
	}
	
    @Produces
    @WebSessionCache
    @ApplicationScoped
    private RemoteCache remoteCache(@WebSessionCache RemoteCacheManager cacheManager){
    	log.info("\n\t ->>> Get the remote cache \n");
    	
    	RemoteCache cache = cacheManager.getCache("default");
    	return cache;
    }
    
    @Produces
    @WebSessionCache
    @ApplicationScoped
    public RemoteCacheManager remoteCacheManager() {
    	log.info("\n\t ->>> Builds the REMOTE-CacheManager \n");
    	
    	org.infinispan.client.hotrod.configuration.Configuration remoteConf = 
    			new org.infinispan.client.hotrod.configuration.ConfigurationBuilder()
    				.tcpNoDelay(true)
    					.connectionPool()
			    	      .numTestsPerEvictionRun(3)
			    	      .testOnBorrow(true)
			    	      .testOnReturn(true)
			    	      .testWhileIdle(true)
    				.addServer()
    					.host(jdgNode1Addr)
    					.port(jdgNode1Port)
    					.host(jdgNode2Addr)
    					.port(jdgNode2Port).build();
    	
        return new RemoteCacheManager(remoteConf);
    }
    
    public void closeRemoteCacheManager(@Disposes @WebSessionCache RemoteCacheManager cm){
    	log.info("\n\t ->>> Stops REMOTE-cache's RemoteCacheManager \n");
    	cm.stop();
    }
    
}
