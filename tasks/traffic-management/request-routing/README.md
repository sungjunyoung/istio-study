# Request Routing

`setup.sh` 로 설치 시 별점이 계속 바뀌는데, 라우팅할 서비스에 대한 명시 없이는 모든 버전에 대해서 
라운드로빈으로 요청을 보내기 때문

여기서는 v1 으로만 라우팅 하도록 하고, 나중에는 헤더 기반으로 트래픽을 특정할 수 있게 한다.

## Virtual Service 적용하기
```bash
kubectl apply -f samplesbookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```

이제 모든 트래픽이 v1 쪽으로만 감

## 유저 인증정보 기반으로 라우팅하기
Jason 유저는 v2 로 가도록 해보자 productpage 는 `end-user` 헤더를 reviews 서비스에게 줌
[JWT Claim 기반 라우팅](https://istio.io/latest/docs/tasks/security/authentication/jwt-route/) 도 가능함

v2 버전은 별점 기능이 들어감

```bash
kubectl apply -f samplesbookinfo/networking/virtual-service-reviews-test-v2.yaml -n bookinfo
```

productpage 를 열고 jason 유저로 로그인해보면 별점이 보임

## 클린업
```bash
kubectl delete -f samplesbookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```