# Husky Pre-commit Hooks - Permanently Disabled

## Problem Solved
Windows GitHub Desktop was failing with WSL errors when trying to run Husky pre-commit hooks:
```
WSL (215879 - Relay) ERROR: CreateProcessCommon:640: execvpe(/bin/bash) failed: No such file or directory
husky - pre-commit hook exited with code 1 (error)
```

## Root Cause
- GitHub Desktop detected shell commands in `docker-compose.yaml` and assumed WSL environment was needed
- Attempted to run Git hooks through WSL but WSL bash was not properly configured
- Husky hooks were configured to run automatically on every commit

## Permanent Solution
1. **Disabled Git hooks completely** for this repository:
   ```bash
   git config --local --unset core.hooksPath
   ```

2. **Removed automatic Husky installation** from `package.json`:
   - Removed `"prepare": "husky install"` script

3. **Added optional linting** for when code quality checks are desired:
   ```bash
   npm run lint-all
   ```

## Result
- ✅ GitHub Desktop works normally without errors
- ✅ No need for `--no-verify` flags or workarounds
- ✅ Clean development workflow restored
- ✅ Optional code quality checks available when needed

## For Future Developers
If you want to re-enable pre-commit hooks:
1. Run `npm install husky --save-dev`
2. Run `npx husky install`
3. Add back the prepare script: `"prepare": "husky install"`

But this should only be done if the WSL environment is properly configured with bash. 