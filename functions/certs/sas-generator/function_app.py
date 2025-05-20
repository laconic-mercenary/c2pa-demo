import json
import azure.functions as func

app = func.FunctionApp()

def rx_json(data: dict) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(data), mimetype="application/json", status_code=200)

@app.route(route="generate-sas", 
           methods=["POST"], 
           auth_level=func.AuthLevel.ANONYMOUS)
def generate_sas(req: func.HttpRequest) -> func.HttpResponse:
    return rx_json({"status": "ok"})
