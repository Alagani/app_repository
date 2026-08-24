# app_repository

Minimal FastAPI service used to demo an app-repo -> GitOps-repo -> ArgoCD pipeline.
GitHub repo: `Alagani/app_repository`. GitOps repo: `Alagani/argocd_repository`.

## Pipeline (`.github/workflows/ci.yml`)

1. **test** — every PR and push to `main`: `ruff check` + `pytest`.
2. **build-and-push** — `main` only: builds the image, pushes to
   `docker.io/jaga9989/simple-python-app:<git-sha>` (immutable tag, never
   `:latest`), scans it with Trivy, fails the build on HIGH/CRITICAL
   vulnerabilities.
3. **update-gitops** — checks out `argocd_repository`, bumps the prod
   overlay's `newTag` to the git SHA, opens a PR there (never pushes to its
   `main` directly), then enables GitHub's native auto-merge on that PR. The
   PR still has to pass `argocd_repository`'s own `validate.yml` checks
   before auto-merge actually lands it — this workflow itself never touches
   the Kubernetes cluster. There's a single environment and no manual
   promotion step anywhere; see that repo's README for the full path from
   merge to a synced cluster.

## Required repo configuration

| Name | Type | Purpose |
|---|---|---|
| `GITOPS_PAT` | Actions secret | Fine-grained PAT on `argocd_repository` only, with **Contents: Read and write** (to open the PR) and **Pull requests: Read and write** (to auto-merge it). A GitHub App installation token is the preferred alternative for org-wide use — ask CTO before adopting. |
| `DOCKERHUB_USERNAME` | Actions secret | Docker Hub username (`jaga9989`). |
| `DOCKERHUB_TOKEN` | Actions secret | Docker Hub **access token** (Account Settings > Security > New Access Token), not your account password. Scope it to this repo/repo-read-write only. |

Branch protection on `main` should require the `test` job before merge.
