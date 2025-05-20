import json
import logging
import azure.functions as func

app = func.FunctionApp()

def rx_json(data: dict) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(data), mimetype="application/json", status_code=200)

@app.route(route="certbot/generate", 
            methods=["GET", "POST"], 
            auth_level=func.AuthLevel.ANONYMOUS)
def generate(req: func.HttpRequest) -> func.HttpResponse:
    return rx_json({"status": "ok"})
