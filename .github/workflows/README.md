# GitHub Actions

`framework-verify.yml` runs on push to main/master, PRs, and tags. Run locally before merge:

```bash
bash scripts/framework-verify.sh
bash scripts/smoke-consumer.sh
```

See `CONTRIBUTING.md` § Verification.
