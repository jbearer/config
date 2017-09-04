# Force bash to check the command after sudo for aliases
alias sudo='sudo '

# Clear the terminal buffer
alias cl="tput reset"

# Add files to the current window instead of opening a new one
alias subl="subl --add"

# Python 3
alias python=python3
alias pip=pip3

# The default of 1s is a bit too slow; we don't lose much by going to 0.2
alias watch="watch -n 0.2"

# Prettier svn commands
alias svn="${HOME}/bin/svn-color.py"

# More convenient front-end for setting the system date
alias date="${HOME}/bin/date.py"

alias echo="echo -e"

alias term=i3-sensible-terminal

alias l1="ls -1"
