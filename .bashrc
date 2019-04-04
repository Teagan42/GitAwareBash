source ~/.bash/colors.sh

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '±' && return
    hg root >/dev/null 2>/dev/null && echo '☿' && return
    echo '○'
}

function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || hostname -s
}

GIT_PROMPT_SYMBOL="${COLOR_LIGHT_BLUE}±"
GIT_PROMPT_PREFIX="${COLOR_LIGHT_GREEN} [$COLOR_NC"
GIT_PROMPT_SUFFIX="${COLOR_LIGHT_GREEN}]$COLOR_NC"
GIT_PROMPT_AHEAD="${COLOR_LIGHT_RED}ANUM$COLOR_NC"
GIT_PROMPT_BEHIND="${COLOR_LIGHT_CYAN}BNUM$COLOR_NC"
GIT_PROMPT_MERGING="${COLOR_LIGHT_MAGENTA}⚡︎$COLOR_NC"
GIT_PROMPT_UNTRACKED="${COLOR_DARK_RED}u$COLOR_NC"
GIT_PROMPT_MODIFIED="${COLOR_DARK_YELLOW}d$COLOR_NC"
GIT_PROMPT_STAGED="${COLOR_DARK_GREEN}s$COLOR_NC"

# Show Git branch/tag, or name-rev if on detached head
function git_branch_name() {
    git branch 2>/dev/null | grep '^*' | colrm 1 2 | tr -d '\n'
}

function parse_git_branch() {
    git_branch_name | sed 's/()//'
}

# Show different symbols as appropriate for various Git repository states
function parse_git_state() {

  # Compose this value via multiple conditional appends.
  local GIT_STATE=""

  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    GIT_STATE=$GIT_STATE$(GIT_PROMPT_AHEAD//NUM/$NUM_AHEAD)
  fi

  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    GIT_STATE=$GIT_STATE$(GIT_PROMPT_BEHIND//NUM/$NUM_BEHIND)
  fi

  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_MERGING
  fi

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_UNTRACKED
  fi

  if ! git diff --quiet 2> /dev/null; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_MODIFIED
  fi

  if ! git diff --cached --quiet 2> /dev/null; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_STAGED
  fi

  if [[ -n $GIT_STATE ]]; then
    GITSTATE=$GIT_PROMPT_PREFIX$GIT_STATE$GIT_PROMPT_SUFFIX
  fi

  echo $GITSTATE
}

# If inside a Git repository, print its branch and state
function git_prompt_string() {
  local git_where="$(git_branch_name)"
  local branch=${git_where##(refs/heads/|tags/)}
  [ -n "$git_where" ] && echo "$COLOR_LIGHT_WHITE on $COLOR_BLUE$branch$(parse_git_state)"
}

# determine Ruby version whether using RVM or rbenv
# the chpwd_functions line cause this to update only when the directory changes
function _update_ruby_version() {
    typeset -g ruby_version=''
    if which rvm-prompt &> /dev/null; then
      ruby_version="$(rvm-prompt i v g)"
    else
      if which rbenv &> /dev/null; then
        ruby_version="$(rbenv version | sed -e "s/ (set.*$//")"
      fi
    fi
}
chpwd_functions+=(_update_ruby_version)

function current_pwd {
    echo $(pwd | sed -e "s,^$HOME,~,")
}

function set_prompt {
    local PROMPT="$COLOR_GREEN\u$COLOR_LIGHT_WHITE at $COLOR_LIGHT_BLUE\h$COLOR_LIGHT_WHITE in $COLOR_YELLOW\W$COLOR_NC$(git_prompt_string)\n$(prompt_char) "
    export PS1=$PROMPT
}
PROMPT_COMMAND='set_prompt'
