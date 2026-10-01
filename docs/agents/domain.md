# Domain docs

## Layout and reading rules

This repo uses a single-context layout:

- GLOSSARY.md at the repo root defines domain terms.
- docs/adr/ contains architecture decision records.

Before exploring code, read the glossary and ADRs relevant to the task.
If these files are absent, proceed silently. The domain-modeling skill
creates them lazily when terms or decisions are resolved.

## Vocabulary

Use glossary terms consistently in issues, proposals, hypotheses, and
tests. Reconsider unfamiliar terms; note real gaps for domain-modeling.

## Decision conflicts

Explicitly identify any proposal that contradicts an existing ADR,
including the ADR reference and the reason to reconsider it.
