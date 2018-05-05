#!/bin/bash

O="-t -t -o TCPKeepAlive=yes -o ServerAliveInterval=30 "
app_name="$(basename $0)"
app_path="$(cd $(dirname $0);pwd)"
. $app_path/config.inc

_SCRIPT_="\
function go_ssh(){ \
	echo 'ssh $O -D $wc_bind $wc_ssh_user@$wc_ssh_host' ; \
	ssh $O -D $wc_bind $wc_ssh_user@$wc_ssh_host ; \
}; \
function go_ssh_loop(){ \
	while true; do go_ssh; done; \
}; \
"
function check_inc(){
	(test "" == "$wc_ssh_user" || test "" == "$wc_ssh_host" || test "" == "$wc_bind")&&echo "$app_path/config.inc is not ready.">&2 && exit 1
}

function check_tmux(){
	test "$TMUX_PANE" != "" && echo "tmux is not supported for the moment. plz, try again out of tmux.">&2 && exit 1
}

function gen_and_nohup(){
	tmp_script="$(mktemp /tmp/$app_name.XXXXX)";
	echo -e "#!/bin/bash\n $_SCRIPT_\n $1" > $tmp_script;
	chmod +x $tmp_script;
	nohup $tmp_script >> /tmp/$app_name.log &
	sleep 1;
	rm $tmp_script;
}

case "$1" in
	"once") check_tmux; check_inc; gen_and_nohup 'go_ssh' ;;
	"forever") check_tmux; check_inc; gen_and_nohup 'go_ssh_loop' ;;
	"stopall") ps -ef|grep -E "$wc_ssh_user@$wc_ssh_host|$app_name" |grep -v "grep"| awk '{print $2}' |xargs kill ;;
	"check") ps -ef|grep -E "$wc_ssh_user@$wc_ssh_host|$app_name" |grep -v "grep"| grep -v "check" ;;
	*) echo "usage: $0 check|once|forever|stopall">&2; exit 1 ;;
esac

