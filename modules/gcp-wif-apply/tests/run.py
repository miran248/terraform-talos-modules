"""Exercise concurrent WIF modules against local, mutually authenticated APIs.

Real local/terracurl providers fetch from two independent TLS servers, each of
which closes its first request to model an API still starting. Only Google is
mocked; no cloud credentials or infrastructure are used. Requires openssl.
"""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import os
import shutil
import socket
import ssl
import subprocess
import tempfile
import threading


def openssl(directory, *args):
    subprocess.run(["openssl", *args], cwd=directory, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def api(directory):
    directory.mkdir()
    openssl(directory, "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-keyout", "key.pem", "-out", "cert.pem", "-days", "1",
            "-subj", f"/CN={directory.name}", "-addext", "subjectAltName=IP:127.0.0.1")

    class Handler(BaseHTTPRequestHandler):
        attempts = {}

        def log_message(self, *_):
            pass

        def do_GET(self):
            self.attempts[self.path] = self.attempts.get(self.path, 0) + 1
            if self.attempts[self.path] == 1:
                self.connection.shutdown(socket.SHUT_RDWR)
                self.connection.close()
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"keys":[],"issuer":"local-test"}')

    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(directory / "cert.pem", directory / "key.pem")
    context.load_verify_locations(directory / "cert.pem")
    context.verify_mode = ssl.CERT_REQUIRED
    server.socket = context.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, Handler.attempts


module = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="gcp-wif-apply-test-") as temporary:
    root = Path(temporary)
    target = root / "module"
    target.mkdir()
    for source in module.glob("*.tf"):
        shutil.copy2(source, target / source.name)
    servers = []
    try:
        fixture = (module / "terraform.tf").read_text()
        for name in ("one", "two"):
            directory = root / name
            server, attempts = api(directory)
            servers.append((server, attempts))
            endpoint = f"https://127.0.0.1:{server.server_port}"
            fixture += f'''
module "{name}" {{
  source = "./module"
  identities = {{ MODULE_NAME = "gcp-wif", ids = {{ oidc_bucket = "test-{name}" }} }}
  cluster = {{ MODULE_NAME = "talos-cluster", cluster_endpoint = "{endpoint}" }}
  apply = {{
    MODULE_NAME = "talos-apply"
    ca_certificate = file("${{path.module}}/{name}/cert.pem")
    client_certificate = file("${{path.module}}/{name}/cert.pem")
    client_key = file("${{path.module}}/{name}/key.pem")
  }}
}}
'''
        (root / "main.tf").write_text(fixture)
        (root / "tests").mkdir()
        (root / "tests" / "concurrent.tftest.hcl").write_text('''
mock_provider "google" {}
run "concurrent_cluster_discovery" {
  command = apply
}
''')
        init = ["terraform", f"-chdir={root}", "init", "-backend=false", "-input=false", "-no-color"]
        if plugin_dir := os.environ.get("TALOS_TEST_PLUGIN_DIR"):
            init.append(f"-plugin-dir={plugin_dir}")
        subprocess.run(init, check=True, stdout=subprocess.DEVNULL)
        subprocess.run(["terraform", f"-chdir={root}", "test", "-no-color"], check=True)
        for _, attempts in servers:
            assert attempts.get("/openid/v1/jwks", 0) >= 2, attempts
            assert attempts.get("/.well-known/openid-configuration", 0) >= 2, attempts
        print("Both independent TLS clients survived transient API EOFs.")
    finally:
        for server, _ in servers:
            server.shutdown()
            server.server_close()
