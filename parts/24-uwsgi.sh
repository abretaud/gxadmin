uwsgi_stats_influx(){ ## uwsgi stats_influx <addr>: InfluxDB formatted output for the current stats
	handle_help "$@" <<-EOF
		Contact a specific uWSGI stats address (requires uwsgi binary on path)
		and requests the current stats + formats them for InfluxDB. For some
		reason it has trouble with localhost vs IP address, so recommend that
		you use IP.

		    $ gxadmin uwsgi stats_influx 127.0.0.1:9191
		    uwsgi.locks,addr=127.0.0.1:9191,group=user_0 count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=signal count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=filemon count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=timer count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=rbtimer count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=cron count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=thunder count=2006859
		    uwsgi.locks,addr=127.0.0.1:9191,group=rpc count=0
		    uwsgi.locks,addr=127.0.0.1:9191,group=snmp count=0
		    uwsgi.general,addr=127.0.0.1:9191 listen_queue=0,listen_queue_errors=0,load=0,signal_queue=0
		    uwsgi.sockets,addr=127.0.0.1:9191,name=127.0.0.1:4001,proto=uwsgi queue=0,max_queue=100,shared=0,can_offload=0
		    uwsgi.worker,addr=127.0.0.1:9191,id=1 accepting=1,requests=65312,exceptions=526,harakiri_count=26,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=17433008661,respawn_count=27,tx=15850829410,avg_rt=71724
		    uwsgi.worker,addr=127.0.0.1:9191,id=2 accepting=1,requests=67495,exceptions=472,harakiri_count=51,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=15467746010,respawn_count=52,tx=15830867066,avg_rt=65380
		    uwsgi.worker,addr=127.0.0.1:9191,id=3 accepting=1,requests=67270,exceptions=520,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14162158015,respawn_count=36,tx=15799661545,avg_rt=73366
		    uwsgi.worker,addr=127.0.0.1:9191,id=4 accepting=1,requests=66434,exceptions=540,harakiri_count=34,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=15740205807,respawn_count=35,tx=16231969649,avg_rt=75468
		    uwsgi.worker,addr=127.0.0.1:9191,id=5 accepting=1,requests=67021,exceptions=534,harakiri_count=38,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14573155758,respawn_count=39,tx=16517287963,avg_rt=140855
		    uwsgi.worker,addr=127.0.0.1:9191,id=6 accepting=1,requests=66810,exceptions=483,harakiri_count=24,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=19107513635,respawn_count=25,tx=15945313469,avg_rt=64032
		    uwsgi.worker,addr=127.0.0.1:9191,id=7 accepting=1,requests=66544,exceptions=460,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14240478391,respawn_count=36,tx=15499531841,avg_rt=114981
		    uwsgi.worker,addr=127.0.0.1:9191,id=8 accepting=1,requests=67577,exceptions=517,harakiri_count=35,signals=0,signal_queue=0,status="idle",rss=0,vsz=0,running_time=14767971195,respawn_count=36,tx=15780639229,avg_rt=201275

		For multiple zerglings you can run this for each and just 2>/dev/null

		    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats_influx 127.0.0.1:9190 2>/dev/null
		    PATH=/opt/galaxy/venv/bin:/sbin:/bin:/usr/sbin:/usr/bin gxadmin uwsgi stats_influx 127.0.0.1:9191 2>/dev/null
		    exit 0

		And it will fetch only data for responding uwsgis.
	EOF
	address="$1"; shift

	# fetch data
	uwsgi=$(which uwsgi)
	data="$($uwsgi --connect-and-read $address 2>&1)"

	echo "$data" | \
		jq -r '.locks[] | to_entries[] |  "uwsgi.locks,addr='$address',group=\(.key) count=\(.value)"' | \
		sed 's/group=user 0/group=user_0/g'

	echo "$data" | \
		jq -r '. | "uwsgi.general,addr='$address' listen_queue=\(.listen_queue),listen_queue_errors=\(.listen_queue_errors),load=\(.load),signal_queue=\(.signal_queue)"'

	echo "$data" | \
		jq -r '.sockets[] | "uwsgi.sockets,addr='$address',name=\(.name),proto=\(.proto) queue=\(.queue),max_queue=\(.max_queue),shared=\(.shared),can_offload=\(.can_offload)"'

	echo "$data" | \
		jq -r '.workers[] | "uwsgi.worker,addr='$address',id=\(.id) accepting=\(.accepting),requests=\(.requests),exceptions=\(.exceptions),harakiri_count=\(.harakiri_count),signals=\(.signals),signal_queue=\(.signal_queue),status=\"\(.status)\",rss=\(.rss),vsz=\(.vsz),running_time=\(.running_time),respawn_count=\(.respawn_count),tx=\(.tx),avg_rt=\(.avg_rt)"' | \
		sed 's/"busy"/1/g;s/"idle"/0/g;'
}
