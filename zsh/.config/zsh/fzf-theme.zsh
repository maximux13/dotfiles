typeset -a FZF_OMP_THEME_COLORS=(
  'fg:#e7ecef'
  'fg+:#ffffff'
  'bg:#0d1323'
  'bg+:#1a2441'
  'alt-bg:#172038'
  'hl:#a3cef1'
  'hl+:#6096ba'
  'current-fg:#ffffff'
  'current-bg:#274c77'
  'current-hl:#ffffff'
  'list-fg:#e7ecef'
  'list-bg:#0d1323'
  'selected-fg:#ffffff'
  'selected-bg:#274c77'
  'selected-hl:#a3cef1'
  'border:#274c77'
  'list-border:#274c77'
  'list-label:#a3cef1'
  'preview-border:#274c77'
  'preview-fg:#e7ecef'
  'preview-bg:#0d1323'
  'preview-scrollbar:#274c77'
  'input-bg:#1c2642'
  'input-fg:#e7ecef'
  'input-border:#6096ba'
  'input-label:#a3cef1'
  'prompt:#6096ba'
  'pointer:#ff6b6b'
  'marker:#ffd93d'
  'spinner:#6096ba'
  'query:#ffffff'
  'ghost:#8b8c89'
  'disabled:#8b8c89'
  'info:#8b8c89'
  'header:#6096ba'
  'header-bg:#141b2f'
  'header-border:#274c77'
  'header-label:#a3cef1'
  'footer:#8b8c89'
  'footer-bg:#0d1323'
  'footer-border:#274c77'
  'footer-label:#a3cef1'
  'label:#a3cef1'
  'gutter:#274c77'
)

FZF_OMP_THEME_COLOR_SPEC=${(j:,:)FZF_OMP_THEME_COLORS}
FZF_OMP_THEME_OPTS="--style=full --border --padding=1,2 --info=inline --layout=reverse --color=${FZF_OMP_THEME_COLOR_SPEC}"

if [[ -n $FZF_DEFAULT_OPTS ]]; then
  export FZF_DEFAULT_OPTS="$FZF_OMP_THEME_OPTS $FZF_DEFAULT_OPTS"
else
  export FZF_DEFAULT_OPTS="$FZF_OMP_THEME_OPTS"
fi
