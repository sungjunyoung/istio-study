# Traffic Shifting

reviews:v1 과 reviews:v3 50:50 으로 받다가, reviews:v3 로 마이그레이션하기

## Weight based routing 적용하기
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```
> 서브셋이 적용되어 있음 (v1 으로 감)

50% 트래픽을 v3 로 가도록 조정하기
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml -n bookinfo
```

테스트가 끝나면, 트래픽 v3 로 모두 가도록 조정하기
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml -n bookinfo
```

## 클린업 
```bash
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```