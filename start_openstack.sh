#!/bin/bash -e

get_docker_ip() {
    docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$1"
}

## Support services
echo "Starting openstack-mysql.."
docker run -d --name openstack-mysql tcpcloud/mysql-server

for i in {1..3}; do
    echo "Starting openstack-memcached0${i}.."
    docker run -d --name openstack-memcached0$i tcpcloud/memcached-server
done

echo "Starting openstack-rabbitmq.."
docker run -d --name openstack-rabbitmq tcpcloud/rabbitmq-server

# Useless sleep, how I like it.. :-)
# (to ensure support services are running)
sleep 60

cat << EOF >> /tmp/env_file.sh
MYSQL_SERVER_SERVICE_HOST=$(get_docker_ip openstack-mysql)
MYSQL_SERVER_SERVICE_PORT=3306

RABBITMQ_NODE_SERVICE_HOST=$(get_docker_ip openstack-rabbitmq)
RABBITMQ_NODE_SERVICE_PORT=3306

MEMCACHED_SERVER_NODE01_SERVICE_HOST=$(get_docker_ip openstack-memcached01)
MEMCACHED_SERVER_NODE01_SERVICE_PORT=11211
MEMCACHED_SERVER_NODE02_SERVICE_HOST=$(get_docker_ip openstack-memcached02)
MEMCACHED_SERVER_NODE02_SERVICE_PORT=11211
MEMCACHED_SERVER_NODE03_SERVICE_HOST=$(get_docker_ip openstack-memcached03)
MEMCACHED_SERVER_NODE03_SERVICE_PORT=11211
EOF

## Keystone
echo "Starting openstack-keystone.."
docker run -d --name openstack-keystone --env-file /tmp/env_file.sh tcpcloud/keystone-server
echo "KEYSTONE_SERVER_SERVICE_HOST=$(get_docker_ip openstack-keystone)" >>/tmp/env_file.sh

sleep 60

## Glance
echo "Starting openstack-glance-registry.."
docker run -d --name openstack-glance-registry --env-file /tmp/env_file.sh tcpcloud/glance-server registry
echo "GLANCE_REGISTRY_HOST=$(get_docker_ip openstack-glance-registry)" >>/tmp/env_file.sh

echo "Starting openstack-glance-api.."
docker run -d --name openstack-glance-api --env-file /tmp/env_file.sh tcpcloud/glance-server api

rm -f /tmp/env_file.sh
