autoload -U add-zsh-hook

# emulate -L zsh scopes clean zsh options (notably no extendedglob), which nvm's
# alias resolution needs. Without it, `setopt extendedglob` in .zshrc breaks
# `nvm use default` and new shells start with no node on PATH.
load-nvmrc() {
  emulate -L zsh
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use --silent
  fi
}
add-zsh-hook chpwd load-nvmrc

# Apply the default node version, or the .nvmrc, for the shell's starting
# directory. chpwd only fires on cd, so this covers the first prompt.
load-nvm-startup() {
  emulate -L zsh
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use --silent
  else
    nvm use default --silent
  fi
}
