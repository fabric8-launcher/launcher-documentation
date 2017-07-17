/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * <p>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.openshift.appdev.documentation.builder;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.Future;
import io.vertx.ext.web.Router;
import io.vertx.ext.web.handler.RedirectAuthHandler;
import io.vertx.ext.web.handler.StaticHandler;

import java.io.IOException;
import java.util.Properties;

public class HttpApplication extends AbstractVerticle {

    private static final String propFileLocation = "/application.properties";
    private static final Properties props = loadProperties();

    private static Properties loadProperties() {
        Properties props = new Properties();
        try {
            props.load(HttpApplication.class.getResourceAsStream(propFileLocation));
        } catch (IOException e) {
            e.printStackTrace();
        }
        return props;
    }

    @Override
    public void start(Future<Void> future) {
        // Create a router object.
        Router router = Router.router(vertx);

        router.get("/health").handler(rc -> rc.response().end("OK"));
        router.get("/latest-launcher-template").handler(rc -> 
        rc.response().setStatusCode(302).putHeader("Location", props.getProperty("launcher.template_url.latest")).end());
        router.route("/").handler(context -> {
            // Redirect to docs
            context.response().putHeader("location", "/docs").setStatusCode(302).end();
        });
        router.get("/docs/*").handler(
                StaticHandler.create().
                setWebRoot(StaticHandler.DEFAULT_WEB_ROOT + "/docs").
                setIndexPage(props.getProperty("launcher.index_page")));

        // Create the HTTP server and pass the "accept" method to the request handler.
        vertx
        .createHttpServer()
        .requestHandler(router::accept)
        .listen(
                // Retrieve the port from the configuration, default to 8080.
                config().getInteger("http.port", 8080), ar -> {
                    if (ar.succeeded()) {
                        System.out.println("Server starter on port " + ar.result().actualPort());
                    }
                    future.handle(ar.mapEmpty());
                });
    }
}
