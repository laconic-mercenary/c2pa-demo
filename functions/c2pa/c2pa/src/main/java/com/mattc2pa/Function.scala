package com.mattc2pa

import java.util.{Map => JMap, Optional}
import com.microsoft.azure.functions._
import com.microsoft.azure.functions.annotation._

class Function {

  @FunctionName("sign")
  def sign(
      @HttpTrigger(
        name = "req",
        methods = Array(HttpMethod.GET, HttpMethod.POST),
        authLevel = AuthorizationLevel.ANONYMOUS,
        route = "sign"
      )
      request: HttpRequestMessage[Optional[String]],
      context: ExecutionContext
  ): HttpResponseMessage = {
    context.getLogger.info("sign invoked")
    val queryParams: JMap[String, String] = request.getQueryParameters
    if (queryParams.containsKey("health")) {
      handleHealthCheck(request)
    } else {
      handleSign(request)
    }
  }

  @FunctionName("verify")
  def verify(
      @HttpTrigger(
        name = "req",
        methods = Array(HttpMethod.GET),
        authLevel = AuthorizationLevel.ANONYMOUS,
        route = "verify"
      )
      request: HttpRequestMessage[Optional[String]],
      context: ExecutionContext
  ): HttpResponseMessage = {
    context.getLogger.info("verify invoked")
    val queryParams: JMap[String, String] = request.getQueryParameters
    if (queryParams.containsKey("health")) {
      handleHealthCheck(request)
    } else {
      handleVerify(request)
    }
  }

  private def handleHealthCheck(request: HttpRequestMessage[Optional[String]]): HttpResponseMessage = {
    request.createResponseBuilder(HttpStatus.OK).body("OK").build()
  }

  private def handleSign(request: HttpRequestMessage[Optional[String]]): HttpResponseMessage = {
    request.createResponseBuilder(HttpStatus.NOT_FOUND).body("Not Found").build()
  }

  private def handleVerify(request: HttpRequestMessage[Optional[String]]): HttpResponseMessage = {
    request.createResponseBuilder(HttpStatus.NOT_FOUND).body("Not Found").build()
  }
}