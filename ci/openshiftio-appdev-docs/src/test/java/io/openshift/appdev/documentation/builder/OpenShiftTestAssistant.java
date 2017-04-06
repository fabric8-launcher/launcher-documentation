package io.openshift.appdev.documentation.builder;

import com.jayway.restassured.RestAssured;
import io.fabric8.kubernetes.api.model.HasMetadata;
import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.client.DefaultKubernetesClient;
import io.fabric8.kubernetes.client.dsl.NamespaceVisitFromServerGetDeleteRecreateApplicable;
import io.fabric8.openshift.api.model.DeploymentConfig;
import io.fabric8.openshift.api.model.Route;
import io.fabric8.openshift.client.OpenShiftClient;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import static com.jayway.awaitility.Awaitility.await;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author <a href="http://escoffier.me">Clement Escoffier</a>
 */
public class OpenShiftTestAssistant {

    private final OpenShiftClient client;
    private final String project;
    private String applicationName;
    private Map<String, NamespaceVisitFromServerGetDeleteRecreateApplicable<List<HasMetadata>, Boolean>> created
        = new LinkedHashMap<>();

    public OpenShiftTestAssistant() {
        client = new DefaultKubernetesClient().adapt(OpenShiftClient.class);
        project = client.getNamespace();
    }

    public List<? extends HasMetadata> deploy(String name, File template) throws IOException {
        try (FileInputStream fis = new FileInputStream(template)) {
            NamespaceVisitFromServerGetDeleteRecreateApplicable<List<HasMetadata>, Boolean> declarations
                = client.load(fis);
            List<HasMetadata> entities = declarations.createOrReplace();
            created.put(name, declarations);
            System.out.println(name + " deployed, " + entities.size() + " object(s) created.");

            return entities;
        }
    }

    public String deployApplication() throws IOException {
        applicationName = System.getProperty("app.name");

        List<? extends HasMetadata> entities
            = deploy("application", new File("target/classes/META-INF/fabric8/openshift.yml"));

        Optional<String> first = entities.stream()
            .filter(hm -> hm instanceof DeploymentConfig)
            .map(hm -> (DeploymentConfig) hm)
            .map(dc -> dc.getMetadata().getName()).findFirst();
        if (applicationName == null && first.isPresent()) {
            applicationName = first.get();
        }

        Route route = client.adapt(OpenShiftClient.class).routes()
            .inNamespace(project).withName(applicationName).get();
        assertThat(route).isNotNull();
        RestAssured.baseURI = "http://" + Objects.requireNonNull(route).getSpec().getHost();
        System.out.println("Route url: " + RestAssured.baseURI);

        return applicationName;
    }

    public void cleanup() {
        List<String> keys = new ArrayList<>(created.keySet());
        Collections.reverse(keys);
        for (String key : keys) {
            System.out.println("Deleting " + key);
            created.remove(key).delete();
        }
    }

    public void awaitApplicationReadinessOrFail() {
        await().atMost(5, TimeUnit.MINUTES).until(() -> {
                List<Pod> list = client.pods().inNamespace(project).list().getItems();
                return list.stream().filter(pod ->
                    pod.getMetadata().getName().startsWith(applicationName))
                    .filter(this::isRunning)
                    .collect(Collectors.toList()).size() >= 1;
            }
        );

    }

    private boolean isRunning(Pod pod) {
        return "running".equalsIgnoreCase(pod.getStatus().getPhase());
    }

    public OpenShiftClient client() {
        return client;
    }

    public String project() {
        return project;
    }

    public String applicationName() {
        return applicationName;
    }

}
