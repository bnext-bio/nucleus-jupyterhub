set -euo pipefail

if [ -n "${EXTRA_PACKAGES}" ]; then
  echo "Updating specified extra packages"
  uv pip install --system ${EXTRA_PACKAGES}
fi