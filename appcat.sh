do_start() {
  AppCatServer &
}

do_stop() {
  pkill -f AppCatServer 
}

case "$1" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  restart)
    do_stop
    do_start
    ;;
esac

exit 0
