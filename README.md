# app_repository

Minimal FastAPI service used to demo an app-repo -> GitOps-repo -> ArgoCD pipeline.
GitHub repo: `Alagani/app_repository`. GitOps repo: `Alagani/argocd_repository`.

## Pipeline (`.github/workflows/ci.yml`)

1. **test** — every PR and push to `main`: `ruff check` + `pytest`.
2. **build-and-push** — `main` only: builds the image, pushes to
   `docker.io/jaga9989/simple-python-app:<git-sha>` (immutable tag, never
   `:latest`), scans it with Trivy, fails the build on HIGH/CRITICAL
   vulnerabilities.
3. **update-gitops** — checks out `argocd_repository`, bumps the dev overlay's
   `newTag` to the git SHA, and opens a PR there (never pushes to its `main`
   directly). Merging that PR is what actually changes what gets deployed —
   this workflow never touches the Kubernetes cluster.

## Required repo configuration

| Name | Type | Purpose |
|---|---|---|
| `GITOPS_PAT` | Actions secret | Fine-grained PAT scoped to `contents:write` on `argocd_repository` only, used to open the image-bump PR. A GitHub App installation token is the preferred alternative for org-wide use — ask CTO before adopting. |
| `DOCKERHUB_USERNAME` | Actions secret | Docker Hub username (`jaga9989`). |
| `DOCKERHUB_TOKEN` | Actions secret | Docker Hub **access token** (Account Settings > Security > New Access Token), not your account password. Scope it to this repo/repo-read-write only. |

Branch protection on `main` should require the `test` job before merge.
