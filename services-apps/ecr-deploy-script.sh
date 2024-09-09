aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 211125583596.dkr.ecr.us-east-1.amazonaws.com



//docker build -t web ./web
docker buildx build --platform=linux/amd64 -t web ./web     
docker tag web 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-web:v1
docker push 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-web:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_web_td_service --force-new-deployment



//docker build -t php ./php
docker buildx build --platform=linux/amd64 -t php ./php        !!In case you use apple m1 chip use this command instead of the first!!
docker tag php 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-php:v1
docker push 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-php:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_php_td_service --force-new-deployment



//docker build -t db ./db
docker buildx build --platform=linux/amd64 -t db ./db        !!In case you use apple m1 chip use this command instead of the first!!
docker tag db 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-db:v1
docker push 211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-db:v1

aws ecs update-service --cluster fgms_ecs_cluster --service fgms_db_td_service --force-new-deployment


