# Control scale gate mutation evidence

The browser gate was deliberately run with the root `--lui-control-h-sm` token changed from `1.75rem` to `1.5rem`, then the stylesheet was restored. The gate exited non-zero as expected and rejected all four required viewport/theme cases:

- 1440px light: 59 findings
- 1440px dark: 59 findings
- 390px light: 60 findings
- 390px dark: 60 findings

The full run output and JSON measurements are included with the hosted QA report linked from the PR discussion.
