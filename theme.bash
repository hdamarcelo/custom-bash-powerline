#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC1091 #Disable following source files for whole script

# Licensed under MIT
# Customized "powerline" prompt for bash tested with Windows (git-bash) and linux
# Based on various powerline projects I stumbled uppon

# To work properly this script needs to be used with a compatible "nerd font" https://www.nerdfonts.com/

# Change this line if the git-prompt.sh script is in another location
# Using itavoids reinventing the whell on how to get repository information
source /usr/share/git-core/contrib/completion/git-prompt.sh

BLK='30'
RED='31'
GRN='32'
YLW='33'
BLU='34'
MAG='35'
CYA='36'
LGR='37'
DFT='39'
DGR='90'
LMG='95'
WHT='97'

RST='\[\e[0m\]'

CURRENT_BG_COLOR=''
CURRENT_FG_COLOR=''
LAST_SECTION_BG_COLOR=''

SEPARATOR_GLYPH=''
ALTERNATE_SEPARATOR_GLYPH='\'
ENDING_GLYPH=''

PS1_STRING=''
PS1_COMPACT_STRING=''

COMPACT_MODE=false
COMPACT_MODE_THRESHOLD=150

JAVA_VERSION=$(java -version 2>&1 | grep -v 'command not found') #For some reason java -version outputs to sterr :P
DOCKER_VERSION=$(docker version 2> /dev/null)
KUBERNETES_CURRENT_CONTEXT=$(kubectl config current-context 2> /dev/null)

# Simple function to roll a 6 sided dice in the terminal.
# Just for fun :)
function d6() {
    local random_number="${RANDOM}"
    local d6_roll=$((1 + random_number % 6))
    case "${d6_roll}" in
    1) echo  ;;
    2) echo  ;;
    3) echo  ;;
    4) echo  ;;
    5) echo  ;;
    6) echo  ;;
    esac
}

# Resets global variables, used each time a new prompt is generated
function theme::reset_strings() {
    CURRENT_BG_COLOR=''
    CURRENT_FG_COLOR=''
    LAST_SECTION_BG_COLOR=''
    PS1_STRING=''
    PS1_COMPACT_STRING=''
}

# Sets background and foreground colors to be used for the next segment(s)
function theme::set_bg_and_fg_colors() {
    CURRENT_BG_COLOR="\[\e[$(( $1 + 10 ))m\]"
    CURRENT_FG_COLOR="\[\e[$2m\]"
}

# Gets the color number from a PS1 ready background color escape sequence
# E.g.: for the color black in the background "\[\e[40m\]" we would get 30
function theme::get_bg_color_number() {
    echo $(( $(echo "$1" | grep -E -o '[0-9]+') - 10 ))
}

# Generates first segment
function theme::generate_prompt_head() {
    local prompt_head=''
    local prompt_head_bg_color=''
    local prompt_head_fg_color=''

    prompt_head_bg_color="${DFT}"
    prompt_head_fg_color="${DGR}"

    theme::set_bg_and_fg_colors "${prompt_head_bg_color}" "${prompt_head_fg_color}"
    prompt_head+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    prompt_head+="╭─${SEPARATOR_GLYPH}"
    PS1_STRING+="${prompt_head}"
    PS1_COMPACT_STRING+="${prompt_head}"
}

# Generates last segment
function theme::generate_prompt_tail() {
    local prompt_tail=''
    local prompt_tail_color=''

    prompt_tail_color="${DGR}"
    LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

    theme::set_bg_and_fg_colors "${DFT}" "${LAST_SECTION_BG_COLOR}"
    prompt_tail+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    prompt_tail+="${ENDING_GLYPH}"
    theme::set_bg_and_fg_colors "${DFT}" "${prompt_tail_color}"
    prompt_tail+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    prompt_tail+="\n╰─ ${RST}"
    PS1_STRING+="${prompt_tail}"
    PS1_COMPACT_STRING+="${prompt_tail}"
}

# Generates user information section. Complete version contains the username
# compact version contains just the user icon ""
function theme::generate_user_section() {
    local user_section=''
    local user_section_bg_color=''
    local user_section_fg_color=''

    user_section_bg_color="${DGR}"
    user_section_fg_color="${WHT}"

    theme::set_bg_and_fg_colors "$user_section_bg_color" "$user_section_fg_color"
    user_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    PS1_STRING+="${user_section}   \u "
    PS1_COMPACT_STRING+="${user_section}   "
}

# Generates working directory section. Complete version contains the whole directory path
# compact version has just the current directory without its parents
function theme::generate_working_directory_section() {
    local working_directory_section=''
    local working_directory_section_bg_color=''
    local working_directory_section_fg_color=''

    working_directory_section_bg_color="${BLU}"
    working_directory_section_fg_color="${WHT}"

    LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

    theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${working_directory_section_bg_color}"
    working_directory_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    working_directory_section+="${SEPARATOR_GLYPH}"

    theme::set_bg_and_fg_colors "${working_directory_section_bg_color}" "${working_directory_section_fg_color}"
    working_directory_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
    PS1_STRING+="${working_directory_section}  \w "
    PS1_COMPACT_STRING+="${working_directory_section}  \W "
}

# Generates source control manager section. Currently only provides information for git repositories.
# Complete version has branch names, branch status and its relation to the upstream branch.
# Compact version only shows the branch status (dirty or not) with color

function theme::generate_scm_section() {
    local scm_section=''
    local git_clean_color=''
    local git_dirty_color=''
    local git_fg_color=''
    local git_bg_color=''
    local git_local_branch=''
    local git_upstream_branch=''
    local git_status_count=''
    local git_ahead_count=''
    local git_behind_count=''
    local git_is_working_directory_dirty=''

    if git status --porcelain > /dev/null 2>&1; then

        git_local_branch=$(__git_ps1 | tr -d '() ') #__git_ps1 from git-prompt.sh

        git_status_count=$(git status --porcelain 2> /dev/null | wc -l)     # Number of modified and untracked files

        if [[ "${git_status_count}" != 0 ]]; then
            git_is_working_directory_dirty=true
        fi

        if [[ -n "${git_local_branch}" ]] && [[ "${git_local_branch}" != "HEAD" ]]; then
            git_upstream_branch=$(git rev-parse --abbrev-ref "@{upstream}" 2> /dev/null)

            if [[ -n "${git_upstream_branch}" ]]; then
                git_ahead_count=$(git rev-list --left-right "${git_local_branch}"..."${git_upstream_branch}" 2> /dev/null | grep -c '^<')  # Get number of commits ahed of the upstream branch
                git_behind_count=$(git rev-list --left-right "${git_local_branch}"..."${git_upstream_branch}" 2> /dev/null | grep -c '^>') # Get number of commits behind of the upstream branch
            fi
        fi

        git_clean_color="${GRN}"
        git_dirty_color="${RED}"
        git_fg_color="${BLK}"

        if [[ "${git_is_working_directory_dirty}" = true ]]; then
            git_bg_color="${git_dirty_color}"
        else
            git_bg_color="${git_clean_color}"
        fi

        LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

        theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${git_bg_color}"
        scm_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        scm_section+="${SEPARATOR_GLYPH}"

        theme::set_bg_and_fg_colors "${git_bg_color}" "${git_fg_color}"
        scm_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        if [[ ${#git_local_branch} -gt 30 ]]; then
            git_local_branch=$(printf "%.27s..." "${git_local_branch}")
        fi
        PS1_COMPACT_STRING+="${scm_section} "
        scm_section+=" ${git_local_branch}"
        if [[ "${git_ahead_count}" -gt 0 ]]; then
            scm_section+="${git_ahead_count}"
        fi
        if [[ "${git_behind_count}" -gt 0 ]]; then
            scm_section+="${git_behind_count}"
        fi
        PS1_STRING+="${scm_section} "
    fi
}

# Generates developer friendly information. Currently shows java version, Docker version, Terminal icon and current Kubernetes context.
# Compact version only shows the icons.
# For both modes information is shown only if:
# - A pom.xml (for java) is found in the current directory
# - A Dockerfile (for Docker) is found in the current directory
# - A .sh or .bash (for Terminal icon) file is found in the current directory
# - A Kubernetes context is set
function theme::generate_coding_section(){
    local coding_section=''
    local coding_section_bg_color=''
    local coding_section_fg_color=''
    local java_version=''
    local docker_version=''
    local kubernetes_current_context=''
    local coding_section_is_empty=true

    coding_section_bg_color="${DGR}"
    coding_section_fg_color="${WHT}"
    
    if [[ -f pom.xml ]]; then
        LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

        if [[ "${coding_section_is_empty}" = true ]]; then
            theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${coding_section_bg_color}"
            coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
            coding_section+="${SEPARATOR_GLYPH}"
        fi

        theme::set_bg_and_fg_colors "${coding_section_bg_color}" "${coding_section_fg_color}"
        coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        if [[ "${coding_section_is_empty}" = false ]]; then
            coding_section+="${ALTERNATE_SEPARATOR_GLYPH}"
        fi
        coding_section+=" "
        coding_section_is_empty=false
    
        if [[ -n "${JAVA_VERSION}" ]]; then
            java_version=$(echo "${JAVA_VERSION}" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]' | head -n 1)
            coding_section+=" ${java_version}"
        fi
    fi

    if [[ -f Dockerfile ]]; then
        LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

        if [[ "${coding_section_is_empty}" = true ]]; then
            theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${coding_section_bg_color}"
            coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
            coding_section+="${SEPARATOR_GLYPH}"
        fi

        theme::set_bg_and_fg_colors "${coding_section_bg_color}" "${coding_section_fg_color}"
        coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        if [[ "${coding_section_is_empty}" = false ]]; then
            coding_section+="${ALTERNATE_SEPARATOR_GLYPH}"
        fi
        coding_section+=" "
        coding_section_is_empty=false

        if [[ -n "${DOCKER_VERSION}" ]]; then
            docker_version=$(echo "${DOCKER_VERSION}" | grep version -i | grep -o -E '[0-9]+\.[0-9]+\.[0-9]' | head -n 1)
            coding_section+=" ${docker_version}"
        fi
    fi

    
    if [[ -n "${KUBERNETES_CURRENT_CONTEXT}" ]]; then
        KUBERNETES_CURRENT_CONTEXT=$(kubectl config current-context 2> /dev/null)
        kubernetes_current_context=$(echo "${KUBERNETES_CURRENT_CONTEXT}" | grep -o -E '/.*' | tr -d '/')
        LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

        if [[ "${coding_section_is_empty}" = true ]]; then
            theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${coding_section_bg_color}"
            coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
            coding_section+="${SEPARATOR_GLYPH}"
        fi

        theme::set_bg_and_fg_colors "${coding_section_bg_color}" "${coding_section_fg_color}"
        coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        if [[ "${coding_section_is_empty}" = false ]]; then
            coding_section+="${ALTERNATE_SEPARATOR_GLYPH}"
        fi
        coding_section+="  "
        coding_section_is_empty=false
        coding_section+="${kubernetes_current_context}"
    fi

    if ls *.sh > /dev/null 2>&1 || ls *.bash > /dev/null 2>&1 || ls *.zsh > /dev/null 2>&1; then
        LAST_SECTION_BG_COLOR=$(theme::get_bg_color_number "${CURRENT_BG_COLOR}")

        if [[ "${coding_section_is_empty}" = true ]]; then
            theme::set_bg_and_fg_colors "${LAST_SECTION_BG_COLOR}" "${coding_section_bg_color}"
            coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
            coding_section+="${SEPARATOR_GLYPH}"
        fi

        theme::set_bg_and_fg_colors "${coding_section_bg_color}" "${coding_section_fg_color}"
        coding_section+="${CURRENT_BG_COLOR}${CURRENT_FG_COLOR}"
        if [[ "${coding_section_is_empty}" = false ]]; then
            coding_section+="${ALTERNATE_SEPARATOR_GLYPH}"
        fi
        coding_section+=" "
        coding_section_is_empty=false
    fi

    PS1_STRING+="${coding_section}"

}

# Calls all thefunctions to generate the segments and updates the PS1 variable
function theme::generate_ps1() {
    if [[ $(tput cols) -lt "${COMPACT_MODE_THRESHOLD}" ]]; then
        COMPACT_MODE=true
    else
        COMPACT_MODE=false
    fi

    theme::reset_strings
    theme::generate_prompt_head
    theme::generate_user_section
    theme::generate_working_directory_section
    theme::generate_scm_section
    if [[ "${COMPACT_MODE}" = false ]]; then 
        theme::generate_coding_section
    fi
    theme::generate_prompt_tail

    if [[ "${COMPACT_MODE}" = true ]]; then 
        export PS1="${PS1_COMPACT_STRING}"
    else
        export PS1="${PS1_STRING}"
    fi

}

export PROMPT_COMMAND=theme::generate_ps1
