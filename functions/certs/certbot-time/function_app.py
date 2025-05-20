import logging
import azure.functions as func

app = func.FunctionApp()

# ⏱️ Timer Trigger for Orchestration
@app.timer_trigger(schedule="0 0 * * * *", 
                    arg_name="schedule", 
                    run_on_startup=True, 
                    use_monitor=False)
def timer(schedule: func.TimerRequest) -> None:
    logging.info("Cert orchestrator timer triggered.")
