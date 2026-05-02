#!/bin/sh
set -e

# 1. Remove old files from previous .Normal versions (ignore missing)
rm -f \
  .codeclimate.yml \
  .eslintrc.json .eslintignore \
  .stylelintrc.json .stylelintignore \
  .mdlrc .mdlrc.style.rb \
  .codacy.yml .travis.yml check-config.sh check-permissions.sh \
  .prettierrc.json \
  .github/workflows/normal.yml
# .prettierrc.json moved into .qlty/configs/

# 2. Create required directories
mkdir -p .qlty/configs .github/workflows .vscode

# 3. EditorConfig + VS Code settings
cp .normal/configs/.editorconfig         .editorconfig
cp .normal/configs/.vscode/settings.json .vscode/settings.json

# 4. Qlty config + all linter/formatter configs
cp .normal/configs/.qlty/qlty.toml   .qlty/qlty.toml
cp -R ".normal/configs/.qlty/configs/." ".qlty/configs/"

# 5. GitHub workflows
cp .normal/configs/.github/dependabot.yml .github/dependabot.yml
for workflow in php python js css sh sql md html xml json yaml env security test-php test-python test-js; do
  cp ".normal/configs/.github/workflows/${workflow}.yml" ".github/workflows/${workflow}.yml"
done
