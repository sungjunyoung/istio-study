# Circuit Breaking

```bash
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n default
```

## Circuit Breaker 설정하기
```bash
kubectl -n default apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF
```
- `outlierDetection.consecutive5xxErrors`: 5XX 에러가 몇개 나면 circuit 열리는지 
- `outlierDetection.baseEjectionTime`: 3분간 circuit 유지

## 클라이언트 추가
```bash
kubectl apply -f samples/httpbin/sample-client/fortio-deploy.yaml -n default
```
```bash
export FORTIO_POD=$(kubectl get pods -n default -l app=fortio -o 'jsonpath={.items[0].metadata.name}')
kubectl exec -n default "$FORTIO_POD" -c fortio -- /usr/bin/fortio curl -quiet http://httpbin:8000/get
```

요청이 성공하는걸 볼 수 있음

## Circuit Breaking 재연해보기
`maxConnections: 1` 이고, `http1MaxPendingRequests: 1` 이기 때문에, 
한개 이상의 요청이 동시에 날라오면 실패하고 circuit 이 열릴것임

2개 커넥션으로 20개 요청을 보내보자
```bash
kubectl exec -n default "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
Code 200 : 5 (16.7 %)
Code 503 : 25 (83.3 %)
```
요청을 더 보내면 503 100% 로 되는걸 볼 수 있음

```bash
kubectl exec -n default "$FORTIO_POD" -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
Code 503 : 30 (100.0 %)
```

매트릭을 확인해보면 `upstream_rq_pending_overflow` 값이 circuit breaker 에 의해 올라가 있는 걸 볼 수 있음
```bash
kubectl -n default exec "$FORTIO_POD" -c istio-proxy -- curl localhost:15000/stats | grep httpbin | grep pending

cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.default.remaining_pending: 1
cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.default.rq_pending_open: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.high.rq_pending_open: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_active: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_failure_eject: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_overflow: 86
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_total: 47
```

## 클린업

```bash
kubectl delete destinationrule httpbin

kubectl delete -f samples/httpbin/sample-client/fortio-deploy.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
```