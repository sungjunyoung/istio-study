# Request Timeout

## 시작하기 전에
```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```

## Request timeouts
request timeout 은 디폴트로 꺼져 있음, virtualservice 스펙으로 timeout 을 추가할 수 있음

1. reviews 서비스 라우팅을 v2 로 변경하기 (ratings 를 호출함)
    ```bash
    kubectl apply -n bookinfo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
        - reviews
      http:
      - route:
        - destination:
            host: reviews
            subset: v2
    EOF
    ```

2. 호출되는 ratings 서비스에 2초 딜레이를 추가하기
    ```bash
    kubectl apply -n bookinfo -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            percent: 100
            fixedDelay: 2s
        route:
        - destination:
            host: ratings
            subset: v1
    EOF
    ```
    페이지 열어보면 아직은 잘 동작하는 걸 확인할 수 있음

3. reviews 서비스에 0.5초 타임아웃을 추가하기
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
      - reviews
      http:
      - route:
        - destination:
            host: reviews
            subset: v2
        timeout: 0.5s
    EOF
    ```

> `x-envoy-upstream-rq-timeout-ms` 아웃바운드 헤더를 추가하면 요청별로 timeout 을 조정할 수 있다.

## 클린업
```bash
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml -n bookinfo
```