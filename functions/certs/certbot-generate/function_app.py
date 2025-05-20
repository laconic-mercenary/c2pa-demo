import json
import logging
import azure.functions as func

from app import CertbotGenerate, GenerateResult, PemData, FingerPrint

app = func.FunctionApp()

def rx_json(data: dict) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(data), mimetype="application/json", status_code=200)

@app.route(route="certbot/generate", 
            methods=["GET", "POST"], 
            auth_level=func.AuthLevel.ANONYMOUS)
def generate(req: func.HttpRequest) -> func.HttpResponse:
    body = req.get_json()
    common_name: str = body["common_name"]
    key_size: int = body.get("key_size", KEY_SIZE_DEFAULT)

    logging.info(f"[certbot-generate] CN={common_name}, key_size={key_size}")

    generator = CertbotGenerate()
    result = generate_key_and_csr(common_name, key_size)

    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=VAULT_URL, credential=credential)

    # Store private key
    key_secret_name = f"cert-key-{result['fingerprint']}"
    client.set_secret(key_secret_name, result["private_key_pem"])

    # Store CSR
    csr_secret_name = f"cert-csr-{result['fingerprint']}"
    client.set_secret(csr_secret_name, result["csr_pem"])

    response_body = {
        "status": "success",
        "fingerprint": result["fingerprint"],
        "vault_key_id": f"{VAULT_URL}secrets/{key_secret_name}",
        "vault_csr_id": f"{VAULT_URL}secrets/{csr_secret_name}"
    }