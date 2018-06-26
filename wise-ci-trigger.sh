#!/bin/sh
server_url="172.20.9.3:8080"
#username="admin@wise2c.com"
#password="********"

if [ $# != 4 ] ; then 
  echo "Usage: $0 tenant_id pipelie_group_id pipeline_id wait/nowait"
  echo " e.g.: $0 1 1 1 wait"
  echo " e.g.: $0 1 1 1 nowait"
  exit 1;
else
  if [ $4 != wait -a $4 != nowait ] ; then
    echo "The 4th parameter should be 'wait' or 'nowait'!"
    echo " e.g.: $0 1 1 1 wait"
    echo " e.g.: $0 1 1 1 nowait"
    exit 1;
  fi
fi

web_header="Content-type: application/json;charset=UTF-8"
#curl -s -X POST -H "${web_header}" http://"$server_url"/api/users/login --data '{"username":"'${username}'","password":"'${password}'"}' > ./api-token.txt
#admin_token='Bearer '`cat ./api-token.txt |awk  -F'"' '{print $4}'`
admin_token='Token I******************************E'

trigger_result=`curl -s -X POST -H "${web_header}" -H "Authorization: ${admin_token}" http://"${server_url}"/api/projects/"$2"/pipelines/"$3"/trigger | jq '.text' | sed 's/\"//g'`

if [ -z $trigger_result ]; then
  exit 1;
else 
  if [ $trigger_result != "流水线触发成功" ] ; then
    exit 1;
  fi
fi

curl -s -X GET -s -H "${web_header}" -H "Authorization: ${admin_token}" http://"${server_url}"/api/tenants/"$1"/pipelines > ./pipelines-info.txt

pipeline_uuid=`cat ./pipelines-info.txt | jq ".[] |select(.project.id==$2)|.pipelines[] |select(.id==$3) |.uuid" |sed 's/\"//g'`

echo Project-ID: $2 / Pipeline-ID: $3 / Pipeline-UUID: $pipeline_uuid / Status: Started
if [ $4 = wait ]; then
  pipeline_state=`curl -s -X GET -s -H "${web_header}" -H "Authorization: ${admin_token}" http://"${server_url}"/api/v2/pipelines/$pipeline_uuid/current | jq '. |.state' |sed 's/\"//g'`
  until [ $pipeline_state = "SUCCESS" -o $pipeline_state = "FAILURE" -o $pipeline_state = "ABORTED" ]
  do
    sleep 10
    pipeline_state=`curl -s -X GET -s -H "${web_header}" -H "Authorization: ${admin_token}" http://"${server_url}"/api/v2/pipelines/$pipeline_uuid/current | jq '. |.state' |sed 's/\"//g'`
    echo Project-ID: $2 / Pipeline-ID: $3 / Pipeline-UUID: $pipeline_uuid / Status: $pipeline_state
  done
  if [ $pipeline_state != "SUCCESS" ]; then
    echo "Task failed."
    exit 1;
  fi
fi

echo "Done."
