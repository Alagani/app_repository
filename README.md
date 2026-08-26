# app_repository

Minimal FastAPI service used to demo an app-repo -> GitOps-repo -> ArgoCD
pipeline. GitHub repo: `Alagani/app_repository`. GitOps repo:
`Alagani/argocd_repository` — that repo's README is where the actual ArgoCD
demo (sync, self-heal, prune) lives; this repo just produces the image it
deploys.

Deploy target is a **kind** cluster on the deployer's own machine (see
`argocd_repository`'s README/`bootstrap.sh`) — no server to provision,
no VM. Image registry is **Docker Hub** (`<dockerhub-username>/myapp-repo`),
created **manually — no Terraform/OpenTofu**. This repo's CI only ever
talks to Docker Hub; it never touches the cluster.

## Pipeline (`.github/workflows/ci.yml`)

1. **test** — every PR and push to `main`: `ruff check` + `pytest`.
2. **build-and-push** — `main` only: logs into Docker Hub with an access
   token (no account password stored), builds the image, pushes it to
   `<dockerhub-username>/myapp-repo:<git-sha>` (git-sha tag by convention —
   Docker Hub has no ECR-style `image_tag_mutability=IMMUTABLE`
   enforcement, so don't reuse a tag by hand, but nothing stops it), then
   scans it with Trivy and fails the build on HIGH/CRITICAL vulnerabilities.
3. **update-gitops** — checks out `argocd_repository`, bumps the prod
   overlay's `newTag` to the git SHA, opens a PR there (never pushes to its
   `main` directly), then enables GitHub's native auto-merge on that PR. The
   PR still has to pass `argocd_repository`'s own `validate.yml` checks
   before auto-merge actually lands it — this workflow itself never touches
   the Kubernetes cluster; that's ArgoCD's job once the merge lands.

There's a single environment and no manual promotion step anywhere in this
repo — see `argocd_repository`'s README for the full path from merge to a
synced cluster.

## Manual setup (no IaC)

Create these once, by hand, then fill in the repo config below:

1. A Docker Hub **repository** named `myapp-repo` under your Docker Hub
   account/org.
2. A Docker Hub **access token** for this workflow (Account Settings ->
   Security -> New Access Token), scoped to read/write on that repo.
3. A **fine-grained GitHub PAT** scoped to `argocd_repository` only, with
   **Contents: Read and write** and **Pull requests: Read and write**, for
   the `update-gitops` job to open and auto-merge its bump PR.
4. On `argocd_repository`: **Allow auto-merge** enabled (Settings >
   General) and `validate.yml`'s jobs set as **required status checks** on
   `main` (Settings > Branches) — otherwise auto-merge won't wait for them.

## Required repo configuration

| Name | Type | Purpose |
|---|---|---|
| `DOCKERHUB_USERNAME` | Actions **variable** (not secret — a username isn't sensitive) | Your Docker Hub username/org. |
| `DOCKERHUB_TOKEN` | Actions secret | The Docker Hub access token created above. |
| `GITOPS_PAT` | Actions secret | The fine-grained PAT on `argocd_repository`, created above. A GitHub App installation token is the preferred alternative for org-wide use — ask CTO before adopting. |

Branch protection on `main` should require the `test` job before merge.
