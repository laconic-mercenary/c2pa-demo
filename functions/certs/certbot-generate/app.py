import cryptography as crypto
import cryptography.hazmat.primitives.asymmetric.rsa as rsa
import cryptography.hazmat.primitives.serialization as serialization
import cryptography.hazmat.primitives.hashes as hashes
import hashlib
import typing 

FingerPrint = str
PemData = str

class GenerateResult:
    def __init__(self, private_key_pem: PemData, csr_pem: PemData, fingerprint: FingerPrint):
        self.private_key_pem = private_key_pem
        self.csr_pem = csr_pem
        self.fingerprint = fingerprint

class CertbotGenerate:
    def generate_key_and_csr(self, common_name: str, key_size: int) -> GenerateResult:
        if common_name is None or len(common_name) == 0:
            raise ValueError("common_name is required")
        if not isinstance(common_name, str):
            raise TypeError("common_name must be a string")
        if key_size is None or key_size < 2048:
            raise ValueError("key_size must be at least 2048")
        if not isinstance(key_size, int):
            raise TypeError("key_size must be an integer")
        
        private_key = rsa.generate_private_key(public_exponent=65537, key_size=key_size)

        csr = crypto.x509.CertificateSigningRequestBuilder().subject_name(crypto.x509.Name([
            crypto.x509.NameAttribute(crypto.x509.NameOID.COMMON_NAME, common_name)
        ])).sign(private_key, crypto.hazmat.primitives.hashes.SHA256())

        fingerprint = hashlib.sha256(
            csr.public_bytes(serialization.Encoding.DER)
        ).hexdigest()

        private_key_pem = private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        ).decode()

        csr_pem = csr.public_bytes(serialization.Encoding.PEM).decode()

        return GenerateResult(
            private_key_pem=PemData(private_key_pem),
            csr_pem=PemData(csr_pem),
            fingerprint=FingerPrint(fingerprint)
        )