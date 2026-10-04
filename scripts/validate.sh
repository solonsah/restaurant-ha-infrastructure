#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repository_root}"

required_commands=(
  ansible-galaxy
  ansible-lint
  ansible-playbook
  yamllint
)

for required_command in "${required_commands[@]}"; do
  if ! command -v "${required_command}" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "${required_command}" >&2
    exit 1
  fi
done

printf '%s\n' "Running YAML validation..."
yamllint \
  .github \
  ansible \
  requirements.yml

printf '%s\n' "Verifying required Ansible collection..."
ansible-galaxy collection list ansible.posix

printf '%s\n' "Running Ansible lint..."
ansible-lint ansible/

printf '%s\n' "Checking audit playbook syntax..."
ansible-playbook \
  -i inventory/example.ini \
  ansible/playbooks/audit.yml \
  --syntax-check

printf '%s\n' "Checking deployment playbook syntax..."
ansible-playbook \
  -i inventory/example.ini \
  ansible/playbooks/deploy.yml \
  --syntax-check

printf '%s\n' "Checking rollback playbook syntax..."
ansible-playbook \
  -i inventory/example.ini \
  ansible/playbooks/rollback.yml \
  --syntax-check

printf '%s\n' "All static validation checks passed."
