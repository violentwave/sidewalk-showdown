# Main Branch Guard

`.github/workflows/main_guard.yml` is a **reactive tripwire**, not branch
protection. GitHub Free does not provide the required branch protection for
this private repository. The workflow runs after each push to `main` and:

- allows a commit only when GitHub associates that exact commit SHA with an
  already-merged PR targeting `main` (the repository's squash-merge path);
- attempts to revert any other pushed commit, then opens an issue with the
  result;
- if GitHub's PR-association API is unavailable, does **not** revert anything
  and opens an issue instead, so a temporary API failure cannot undo a valid
  merge.

## Required landing procedure

1. Branch from `origin/main`.
2. Open a PR and wait for all required checks to pass.
3. Squash-merge the PR and delete the branch.

This is the normal path for OpenCode and other contributors. Do not push
directly to `main`; the guard acts only after a push, so it cannot prevent a
briefly visible bad commit or its CI run.

## Limitations

- A direct multi-commit push is detected by its head commit; earlier commits in
  that push may remain.
- Reverting can fail if later changes conflict or the push races with another
  update. The alert issue reports whether manual repair is needed.
- The repair push uses GitHub Actions' token and does not recursively start a
  second workflow run.

For a true pre-merge gate, upgrade the repository to a plan that supports
branch protection, then require PR reviews/status checks and enforce the rules
for administrators as well.
