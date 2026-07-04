# OSC2026 Acceptance Evidence

## Project

- Name: MoonBit JSONPath
- Module: `ppyj663/moon-jsonpath`
- GitHub: <https://github.com/ppyj663/moon-jsonpath>
- GitLink: <https://gitlink.org.cn/ppyj663/moon-jsonpath>
- License: Apache-2.0
- Primary language: MoonBit

## Delivered Scope

This project provides a compact JSONPath parser and evaluator for `moonbitlang/core/json`. The accepted v0.1.0 scope covers:

- Root selector: `$`
- Object child selector: `.<name>`
- Bracket child selector: `['<name>']` and `["<name>"]`
- Recursive descendant selector: `$..name`
- Object and array wildcard selectors: `.*` and `[*]`
- Zero-based array index selector: `[0]`, `[1]`, and similar non-negative indices

Unsupported syntax is intentionally documented: filters, slices, unions, negative indices, and function extensions.

## Verification Commands

Run from the repository root:

```bash
moon version --all
moon update
moon fmt --check
moon check --warn-list +73
moon test
moon run cmd/main
git diff --check
```

The GitHub Actions workflow in `.github/workflows/ci.yml` runs the same MoonBit validation path on pushes and pull requests.

## Acceptance Checklist

- Public repositories: GitHub and GitLink are public.
- Documentation: README describes goals, install path, examples, supported syntax, API, tests, and limitations.
- Runnable example: `moon run cmd/main` executes a real JSONPath query.
- Tests: `jsonpath_test.mbt` covers successful queries, empty-result queries, and invalid syntax.
- CI: `.github/workflows/ci.yml` validates the package on GitHub.
- License: `LICENSE` is Apache-2.0.
- Report: `report.pdf` summarizes the project and verification evidence.
- Mooncakes: publish target is `ppyj663/moon-jsonpath`. `moon package` validates this package name locally. A `moon publish --dry-run` package check passed, but the final server step was blocked because the local Mooncakes session is authenticated as `caassien`, while the module owner is `ppyj663`. Re-run `moon login` as `ppyj663`, then `moon publish`.

## Maintenance Notes

- Keep the README support matrix aligned with implemented syntax.
- Add tests before expanding syntax support.
- Re-run `moon info` when public APIs change and review generated interfaces before release.
