# TCP Traffic Shifting

TCP 트래픽을 바꿔보자 
`tcp-echo:v1` 을 100% 받다가, `tcp-echo:v2` 로 20% 를 받도록 변경할 것임

## 테스트 환경 셋업
```bash
kubectl create namespace istio-io-tcp-traffic-shifting
kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
kubectl apply -f samples/sleep/sleep.yaml -n istio-io-tcp-traffic-shifting
kubectl apply -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
```

## Weight based TCP 라우팅 적용
모든 TCP 트래픽을 v1 으로 보내기
```bash
kubectl apply -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
```

> ingressgateway 가 31400 에서 service expose 되어 있어야함
> 외부로 완전 노출시키려면 SG 까지 등록

테스트 해보면 one 만 나오는걸 볼 수 있음
```bash
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
for i in {1..20}; do \
kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
-c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done
```

이제 v2 로 20% 트래픽을 보내기
```bash
kubectl apply -f samples/tcp-echo/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
```

다시 테스트해보면, two 가 20% 섞여서 옴
```bash
for i in {1..20}; do \
kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
-c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done

one Sat Oct 15 13:44:21 UTC 2022
one Sat Oct 15 13:44:23 UTC 2022
one Sat Oct 15 13:44:25 UTC 2022
one Sat Oct 15 13:44:26 UTC 2022
one Sat Oct 15 13:44:28 UTC 2022
one Sat Oct 15 13:44:30 UTC 2022
one Sat Oct 15 13:44:32 UTC 2022
two Sat Oct 15 13:44:34 UTC 2022
one Sat Oct 15 13:44:36 UTC 2022
one Sat Oct 15 13:44:37 UTC 2022
one Sat Oct 15 13:44:39 UTC 2022
one Sat Oct 15 13:44:41 UTC 2022
one Sat Oct 15 13:44:43 UTC 2022
one Sat Oct 15 13:44:45 UTC 2022
one Sat Oct 15 13:44:47 UTC 2022
one Sat Oct 15 13:44:48 UTC 2022
one Sat Oct 15 13:44:50 UTC 2022
one Sat Oct 15 13:44:52 UTC 2022
two Sat Oct 15 13:44:54 UTC 2022
two Sat Oct 15 13:44:56 UTC 2022
```

## Cleanup
```bash
kubectl delete -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/sleep/sleep.yaml -n istio-io-tcp-traffic-shifting
kubectl delete namespace istio-io-tcp-traffic-shifting
```