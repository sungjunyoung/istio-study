# Fault Injection

## 시작하기 전에
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml -n bookinfo
```

## HTTP Delay Fault 추가하기
jason 유저에게만 fault injection 추가하기
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml -n bookinfo
```

jason 유저로 접속하면 7초동안 로딩 화면이 보여지고 결국 로드가 되긴 하지만, 
reviews 섹션이 에러 메시지를 보여줌

productpage 와 reviews 서비스 사이에는 3초 타임아웃, 1번 리트라이가 하드코딩 되어 있기 때문

## 버그 고쳐보기
reviews:v3 에 이미 고쳐져 있음, 한번 해보기

## HTTP Abort Fault 추가하기
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml -n bookinfo
```

## 클린업
```bash
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```