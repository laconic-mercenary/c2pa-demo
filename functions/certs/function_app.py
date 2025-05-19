import json
import logging
import azure.functions as func

app = func.FunctionApp()

def rx_json(data: dict) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(data), mimetype="application/json", status_code=200)

# Health Check
@app.route(
        route="health", 
        methods=["GET"], 
        auth_level=func.AuthLevel.ANONYMOUS
    )
def health(req: func.HttpRequest) -> func.HttpResponse:
    return rx_json({"status": "ok"})

# 🧠 CSR Generation
@app.route(
        route="certbot/generate", 
        methods=["POST"], 
        auth_level=func.AuthLevel.ANONYMOUS
    )
def generate(req: func.HttpRequest) -> func.HttpResponse:
    return rx_json({"csr": "mocked"})

# 🔁 Cert Update Stub
@app.route(
        route="certbot/update", 
        methods=["POST"], 
        auth_level=func.AuthLevel.ANONYMOUS
    )
def update(req: func.HttpRequest) -> func.HttpResponse:
    return rx_json({"updated": True})

# ⏱️ Timer Trigger for Orchestration
@app.timer_trigger(
        schedule="0 0 * * * *", 
        arg_name="schedule", 
        run_on_startup=True, 
        use_monitor=True
    )
def timer(schedule: func.TimerRequest) -> None:
    logging.info("Cert orchestrator timer triggered.")
