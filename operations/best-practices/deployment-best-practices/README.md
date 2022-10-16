# Deployment Best Practices

설정 이슈를 줄이고 워크로드 관리를 쉽게

## Deploy fewer clusters
작은 클러스터를 많이 만들지 말고 큰 클러스터를 작은 숫자로 만들기, 클러스터를 추가하는것 보다, 관리를 위해 namespace tanency 를 사용
이런 접근 방식으로, 하나 이상의 클러스터를 zone 이나 region 별로 배포할 수 있음. 그러고 control plane 을 zone/region 별로 하나의 클러스터에서 운영

## Deploy clusters near your users
유저와 가까운 곳에서 클러스터 운영

## Deploy across multiple availability zones