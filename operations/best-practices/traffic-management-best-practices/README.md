# Traffic Management Best Practices

## 서비스에 Default Route 설정
Istio 가 아무 설저 없이도 트래픽을 destination 으로 잘 보내 주지만, 모든 서비스에 `VirtualService` 를 항상 생성해 주는 것을 추천

처음에 서비스의 버전이 하나뿐인 경우에도 두 번째 버전을 배포하기로 결정하자마자 
새 버전이 시작되기 전에 라우팅 규칙을 설정해서 서비스가 제어되지 않는 방식으로 트래픽을 즉시 수신하지 못하도록 해야 함

Istio의 기본 라운드로빈 라우팅에 의존할 때 또 다른 잠재적인 문제는 Istio 의 `DestinationRule` 평가 알고리즘의 미묘함 때문
요청이 라우팅 될 때, Envoy 는 특정 subset 이 라우팅 되는지 확인하기 위해 `VirtualService` 의 라우팅 룰을 평가함. 
그렇다면, 그 `DestinationRule` subset 에 일치하는 정책에 대해서만 활성화 시킴. 그 결과로 Istio 는 해당 subset 으로 명시적으로 
라우팅한 경우에만 특정 subset 에 대해 정의한 정책을 적용함

정리하면, `VirtualService` 에 라우팅 subset 을 `명시` 하지 않으면, `DestinationRule` 에서 subset 하위로 들어간 `trafficPolicy` 는 적용되지 않음
예를 들어, 아래와 같이 `DestinationRule` 스펙이 있을 때,

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
```

`subsets:v1` 하위의 trafficPolicy 는 `VirtualService` 에 subset 을 명시적으로 v1 으로 주지 않는 한 적용되지 않음
이렇게 줘야 default subset 을 사용하더라도 제대로 적용됨

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
```

혹은, 아래처럼 무조건 `VirtualService` 에 subset 명시하기
```yaml
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
        subset: v1
```

## 네임스페이스간 공유되는 설정 컨트롤하기
`VirtualService`, `DestinationRule` 들은 한 네임스페이스에 생성하고 다른 네임스페이스에서도 사용이 가능함
기본적으로 이런 리소스들은 모든 네임스페이스에서 공유될 수 있음, 그러나, `exportTo` 스펙을 사용하면 특정 네임스페이스에서만 보이도록 제한이 가능함

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myservice
spec:
  hosts:
  - myservice.com
  exportTo:
  - "."
  http:
  - route:
    - destination:
        host: myservice
```

`DestinationRule` 을 다른 네임스페이스에서 사용하려면, `DestinationRule` lookup path 에 있어야함
1. client namespace
2. service namespace
3. root namespace (default: istio-system)

아래와 같은 `DestinationRule` 을 `ns1` 네임스페이스에 만들었다고 가정
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: myservice
spec:
  host: myservice.default.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
```

- `ns1` 네임스페이스에서 요청을 보내면 응답. 왜냐하면 `DestinationRule` 가 생성되있는 곳(`ns1`)이 client 네임스페이스(`ns1`)이기 때문
- `ns2` 네임스페이스에서 요청을 보내면 응답하지 못함. 왜냐하면 `DestinationRule` 가 생성되어 있는 곳(`ns1`)이 client 네임스페이스(`ns2`) 이 아니고, 
  타겟 서비스는 `default` 에 있기 때문에, 찾을 수 없음, 적용되지 못할 것

`DestinationRule` 을 `Service` 일치하는 네임스페이스에 생성해서 해결할 수 있음
예제에서는 `default` 네임스페이스. 이러면 모든 네임스페이스에서 적용이 가능함. 혹은 `istio-system` (root namespace) 에 생성


## 비대한 VirtualService 와 DestinationRule 을 여러 리소스로 쪼개기
`istio-pilot` 이 라우팅 룰들을 합쳐줌 고려사항이 있긴 함.

- `VirtualService`
  - 한개 리소스에서 라우팅 우선순위는 정해지지만, 여러 리소스에 대한 우선순위는 정해지지 않음, 그래서 중복되는게 없도록 잘 쪼개야함
  - gateway 에 바인드 되어 있어야 머지가 된다. 사이드카 단에서는 머지 안됨
- `DestinationRule`
  - 역시 중복되는게 없어야함
  - 한 개의 top-level `trafficPolicy` 만이 있어야 함. subset 별로의 `trafficPolicy` 들만 있다면 첫번째만 선택되어 적용됨
  - `VirtualService` 와는 다르게 사이드카와 게이트웨이에서 둘 다 머지됨

## 서비스 라우팅 변경할 때 503 피하기
특정 서비스의 subset 라우팅을 변경할 때, subset 이 available 한지 체크 해야함. 하지 않으면 503 에러가 올라옴
단일 kubectl 커맨드로 `VirtualService` 와 `DestinationRule` 을 동시 적용하는것은 리소스 propagation 때문에 충분하지 않음
`VirtualService` 가 없는 subset 에 대해 먼저 적용하려고 하면, 503 에러가 떨어지기 때문

zero down-time 을 가지려면,

- 새로운 subset 을 생성할 때
  - `VirtualService` 를 생성하기 전에 `DestinationRule` 부터 적용할 것 
  - `DestinationRule` 을 적용한 후 몇초 대기하고 `VirtualService` 적용
- subset 을 삭제할 때
  - 역순으로 `VirtualService` 부터 적용하고 `DestinationRule` 적용, (sidecar 에 반영이 되었는지 확인하기)
