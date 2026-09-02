from __future__ import annotations

import re
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory


ROOT = Path(__file__).resolve().parents[2]
AGENTS_BASELINE_CHARS = 22_635
CANONICAL_SKILL = "terraform-talos-modules"
ALTERNATE_AGENT_ROOTS = (
    ".agent",
    ".aider",
    ".claude",
    ".codex",
    ".continue",
    ".cursor",
    ".gemini",
    ".hermes",
    ".roo",
    ".windsurf",
    "agent",
    "agents",
)


def _alternate_agent_roots(root: Path) -> list[Path]:
    return [root / name for name in ALTERNATE_AGENT_ROOTS if (root / name).exists()]


class AgentAssetsTest(unittest.TestCase):
    def test_alternate_agent_roots_are_detected(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".cursor").mkdir()
            (root / "agents").mkdir()

            self.assertEqual(
                _alternate_agent_roots(root),
                [root / ".cursor", root / "agents"],
            )

    def test_only_canonical_agent_asset_tree_exists(self) -> None:
        self.assertEqual(_alternate_agent_roots(ROOT), [])
        skill_files = sorted(ROOT.rglob("SKILL.md"))
        self.assertEqual(
            skill_files,
            [ROOT / ".agents" / "skills" / CANONICAL_SKILL / "SKILL.md"],
        )

    def test_canonical_skill_has_exact_name_and_valid_references(self) -> None:
        skill = ROOT / ".agents" / "skills" / CANONICAL_SKILL / "SKILL.md"
        text = skill.read_text()
        self.assertTrue(text.startswith("---\n"))
        self.assertRegex(text, rf"(?m)^name: {re.escape(CANONICAL_SKILL)}$")
        description = re.search(r"(?m)^description: (.+)$", text)
        if description is None:
            self.fail("missing skill description")
        value = description.group(1).strip('"')
        self.assertLessEqual(len(value), 60)
        self.assertTrue(value.endswith("."))

        references = re.findall(r"`(references/[^`]+\.md)`", text)
        self.assertEqual(
            set(references),
            {
                "references/modules.md",
                "references/networking.md",
                "references/operations.md",
                "references/release.md",
                "references/verification.md",
            },
        )
        for reference in references:
            self.assertTrue((skill.parent / reference).is_file(), reference)

    def test_contract_topics_are_preserved_on_demand(self) -> None:
        skill_dir = ROOT / ".agents" / "skills" / CANONICAL_SKILL
        corpus = "\n".join(path.read_text() for path in skill_dir.rglob("*.md"))
        for topic in (
            "Terraform",
            "Kubernetes",
            "Talos",
            "Release Please",
            "module",
            "verification",
            "KUBECONFIG=kube-config",
            "TALOSCONFIG=talos-config",
        ):
            self.assertIn(topic, corpus)

    def test_concrete_scope_contracts_are_preserved(self) -> None:
        contracts = {
            "packer/AGENTS.md": (
                "explicit variables",
                "environment-specific paths, buckets, usernames, and tags",
                "cleanup of temporary image material after successful builds",
            ),
            "local/AGENTS.md": (
                "stable Talos CLI",
                "one control plane",
            ),
            "manifests/AGENTS.md": (
                "Each component directory owns its `kustomization.yaml`",
                "patches/resources, chart version, and Helm values",
                "change component intent in the owning Kustomization",
                "kube-proxy-disabled Talos patches",
                "selected DNS/KubeSpan behavior",
            ),
            "modules/talos-cluster/AGENTS.md": (
                "certificate SANs",
                "host aliases",
                "rendered `user_data`",
                "common and control-plane machine configuration for each address family",
            ),
        }
        for relative_path, invariants in contracts.items():
            text = (ROOT / relative_path).read_text()
            for invariant in invariants:
                with self.subTest(path=relative_path, invariant=invariant):
                    self.assertIn(invariant, text)

    def test_agents_hierarchy_is_compact_and_has_no_empty_boilerplate(self) -> None:
        agents_files = sorted(ROOT.rglob("AGENTS.md"))
        self.assertEqual(len(agents_files), 16)
        total_chars = sum(len(path.read_text()) for path in agents_files)
        self.assertLess(total_chars, AGENTS_BASELINE_CHARS * 0.65)
        for path in agents_files:
            text = path.read_text()
            self.assertNotRegex(text, r"(?m)^## (Work Guidance|Child DOX Index)\s*$")
            for link in re.findall(r"\[[^]]+\]\(([^)]+AGENTS\.md)\)", text):
                self.assertTrue((path.parent / link).resolve().is_file(), f"{path}: {link}")


if __name__ == "__main__":
    unittest.main()
