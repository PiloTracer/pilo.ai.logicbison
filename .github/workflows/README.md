# GitHub Actions disabled

`framework-verify.yml` was removed intentionally. Run verifiers locally before merge or tag:

```bash
bash scripts/framework-verify.sh
bash scripts/smoke-consumer.sh
```

See `CONTRIBUTING.md` § Verification.
