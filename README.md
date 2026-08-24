# app_repository

Minimal FastAPI service used to demo an app-repo -> GitOps-repo -> ArgoCD pipeline.
GitHub repo: `Alagani/app_repository`. GitOps repo: `Alagani/argocd_respository`.

## Pipeline (`.github/workflows/ci.yml`)

1. **test** — every PR and push to `main`: `ruff check` + `pytest`.
2. **build-and-push** — `main` only: builds the image, pushes to
   `ghcr.io/alagani/fastapi-app:<git-sha>` (immutable tag, never `:latest`),
   scans it with Trivy, fails the build on HIGH/CRITICAL vulnerabilities.
3. **update-gitops** — checks out `argocd_respository`, bumps the dev overlay's
   `newTag` to the git SHA, and opens a PR there (never pushes to its `main`
   directly). Merging that PR is what actually changes what gets deployed —
   this workflow never touches the Kubernetes cluster.

## Required repo configuration

| Name | Type | Purpose |
|---|---|---|
| `GITOPS_PAT` | Actions secret | Fine-grained PAT scoped to `contents:write` on `argocd_respository` only, used to open the image-bump PR. A GitHub App installation token is the preferred alternative for org-wide use — ask CTO before adopting. |

`GITHUB_TOKEN` (built-in) is used for the GHCR push — no extra registry
credential needed. Enable "Read and write permissions" for `GITHUB_TOKEN` at
the repo level, or keep the `permissions:` block in the workflow (already set).

Branch protection on `main` should require the `test` job before merge.
