package com.mattc2pa;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;

import java.util.Map;
import java.util.Optional;

import com.mattc2pa.app.ManifestService;
import com.mattc2pa.app.ManifestServiceFactory;

public class Function {
   
   @FunctionName("sign")
    public HttpResponseMessage sign(
        @HttpTrigger(
            name = "req",
            methods = {HttpMethod.GET, HttpMethod.POST},
            authLevel = AuthorizationLevel.ANONYMOUS,
            route = "sign"
        )
        HttpRequestMessage<Optional<String>> request,
        final ExecutionContext context
    ) {
        context.getLogger().info("sign invoked");
        final Map<String, String> queryParams = request.getQueryParameters();
        if (queryParams.containsKey("health")) {
            return handleHealthCheck(request);
        }
        return handleSign(request);
    }

    @FunctionName("verify")
    public HttpResponseMessage verify(
        @HttpTrigger(
            name = "req",
            methods = {HttpMethod.GET},
            authLevel = AuthorizationLevel.ANONYMOUS,
            route = "verify"
        ) 
        HttpRequestMessage<Optional<String>> request,
        final ExecutionContext context
    ) {
        context.getLogger().info("verify invoked");
        final Map<String, String> queryParams = request.getQueryParameters();
        if (queryParams.containsKey("health")) {
            return handleHealthCheck(request);
        }
        return handleVerify(request);
    }

    private static HttpResponseMessage handleHealthCheck(HttpRequestMessage<Optional<String>> request) {
        return request.createResponseBuilder(HttpStatus.OK)
                                    .body("OK")
                                    .build();
    }

    private static HttpResponseMessage handleSign(HttpRequestMessage<Optional<String>> request) {
        return request.createResponseBuilder(HttpStatus.NOT_FOUND)
                        .body("Not Found")
                        .build();
    }

    private static HttpResponseMessage handleVerify(HttpRequestMessage<Optional<String>> request) {
        final ManifestService manifestService = new ManifestServiceFactory()
                                                    .withLogging()
                                                    .finish();
        return request.createResponseBuilder(HttpStatus.NOT_FOUND)
                        .body("Not Found")
                        .build();
    }
}
