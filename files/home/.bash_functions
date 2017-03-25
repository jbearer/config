function launch()
{
    nohup "$@" &> /dev/null &
    disown
}
