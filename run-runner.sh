#!/bin/bash

if [[ "$#" -lt 1 ]]; then
    echo -e "Requires url and registration-token registration token.\nExample: ./deploy-runner.sh server.lan:44324 87HGMEnx-pAMefMyvenxJ"
    exit 1
fi

url=$1
file_name=${url%:*}
token=$2
volume=gitlab-runner-config

echo "##############################"
echo url: $url
echo file: $file_name
echo token: $token
echo volume: $volume
echo "##############################"

docker volume rm ${volume}
docker volume create ${volume}

docker run -d --name gitlab-runner --restart always \
   		   -v /var/run/docker.sock:/var/run/docker.sock \
   		   -v ${volume}:/etc/gitlab-runner \
   		    gitlab/gitlab-runner:latest

# Копируем сертификаты на GitLab runner 
docker cp keys/${file_name}.crt gitlab-runner:/etc/gitlab-runner/certs/${file_name}.crt
docker cp keys/${file_name}.key gitlab-runner:/etc/gitlab-runner/certs/${file_name}.key

#WARNING: The 'register' command has been deprecated in GitLab Runner 15.6 and will be replaced with a 'deploy' command. For more information, see https://gitlab.com/gitlab-org/gitlab/-/issues/380872 
docker exec -it gitlab-runner gitlab-runner register \
                     --non-interactive \
                     --executor "docker" \
                     --docker-image alpine:latest \
                     --url "https://${url}" \
                     --registration-token "${token}" \
                     --description "docker-runner" \
                     --maintenance-note "Free-form maintainer notes about this runner" \
                     --tag-list "docker" \
                     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
                     --run-untagged="true" \
                     --locked="false" \
                     --access-level="not_protected"
                     #--tls-ca-file "/etc/gitlab-runner/certs/ca.crt"
