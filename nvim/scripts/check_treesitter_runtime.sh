#!/usr/bin/env bash
set -euo pipefail

SITE_PARSER_DIR="${HOME}/.local/share/nvim/site/parser"
LEGACY_TS_DIR="${HOME}/.local/share/nvim/lazy/nvim-treesitter/parser"

mkdir -p "${SITE_PARSER_DIR}"

# Python was previously only available from the archived nvim-treesitter path.
# If that legacy parser still exists, promote it into the normal site parser dir.
# This is a one-time compatibility bridge: once the archived plugin directory is
# cleaned up, this script becomes a validator only.
if [[ ! -f "${SITE_PARSER_DIR}/python.so" && -f "${LEGACY_TS_DIR}/python.so" ]]; then
  cp "${LEGACY_TS_DIR}/python.so" "${SITE_PARSER_DIR}/python.so"
  echo "bootstrapped python.so into ${SITE_PARSER_DIR}"
fi

langs=(json lua markdown markdown_inline python vim vimdoc)

for lang in "${langs[@]}"; do
  nvim --headless \
    "+lua local lang='${lang}'; local ok, err = pcall(vim.treesitter.start, 0, lang); local okq, files = pcall(vim.treesitter.query.get_files, lang, 'highlights'); io.write(string.format('%s %s %s\\n', lang, ok and 'parser=ok' or ('parser=fail:' .. tostring(err)), okq and ('queries=' .. #files) or ('queries=fail:' .. tostring(files))))" \
    "+qall"
done
