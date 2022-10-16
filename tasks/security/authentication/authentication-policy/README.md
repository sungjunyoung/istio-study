# Authentication Policy

## PeerAuthentication

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
```
root 네임스페이스 (isstio-system) 에 `PeerAuthentication` 을 적용하면 클러스터에 전체 istio-proxy 를 가진 워크로드들이 
mTLS 모드로 동작한다.

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
```
특정 네임스페이스를 지정하면 해당 네임스페이스를 향하는 요청들이 mTLS 모드로 동작한다.
istio-proxy 사이드카를 가지지 않은 워크로드가 요청하면 deny 된다.

```bash
cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
```
selector 를 지정해서 특정 워크로드를 지정하면, 해당 워크로드는 mTLS 로만 호출할 수 있다.

```bash
cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    80:
      mode: DISABLE
EOF
```
`portLevelMtls` 로 특정 포트만 mTLS 를 끄거나 켤 수 있다.
root 네임스페이스로 지정하더라도, 더 낮은 레벨로 `PeerAuthentication` 을 추가하면 overwrite 할 수 있다.

## End user Authentication
```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.15/security/tools/jwt/samples/jwks.json"
EOF
```

`RequestAuthentication` 을 사용하면 jwt 토큰을 강제할 수 있다.

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
```

`AuthorizationPolicy` 를 사용해서 특정 Path 에 대한 요청만 jwt 토큰 없이 허용할 수 있다.

