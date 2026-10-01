"""Run mocked Terraform plans without opening an ephemeral Talos connection.

Terraform mock providers do not support ephemeral resources. Only the drain
credential lookup is replaced in a temporary copy; machine resources and their
endpoint/node expressions are tested unchanged. No infrastructure is contacted.
"""

from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

module = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="talos-apply-test-") as directory:
    target = Path(directory)
    for source in module.glob("*.tf"):
        shutil.copy2(source, target / source.name)
    shutil.copytree(module / "tests", target / "tests")
    main = target / "main.tf"
    source, count = re.subn(
        r'^ephemeral "talos_cluster_kubeconfig" "drain" \{\n.*?^\}\n',
        "",
        main.read_text(),
        flags=re.MULTILINE | re.DOTALL,
    )
    if count != 1:
        raise RuntimeError("Expected exactly one ephemeral drain credential lookup")
    main.write_text(source.replace(
        "ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw",
        '"unused-mocked-kubeconfig"',
    ))
    init = ["terraform", f"-chdir={target}", "init", "-backend=false", "-input=false", "-no-color"]
    if plugin_dir := os.environ.get("TALOS_TEST_PLUGIN_DIR"):
        init.append(f"-plugin-dir={plugin_dir}")
    subprocess.run(init, check=True, stdout=subprocess.DEVNULL)
    result = subprocess.run(["terraform", f"-chdir={target}", "test", "-no-color"])
    sys.exit(result.returncode)
