# Plugin in CA Certificates

이 작업은 관리자가 어떻게 루트 인증서, 서명 인증서 및 키를 사용하여 Istio CA (인증 기관) 를 구성하는지 보여줍니다.

기본적으로 Istio CA 는 self-signed 루트 인증서와 키를 생성하고, 워크로드 인증서에 서명하기 위해 이를 사용합니다.
root CA key 를 보호하기 위해 오프라인 시스템에서 root CA 를 사용하고 root CA 를 사용하여 각 클러스터에서 실행되는 Istio CA 에 중간 인증서를 발급해야 합니다.
Istio CA 는 관리자가 지정한 인증서 및 키를 사용하여 워크로드 인증서를 서명하고, 관리자 지정 root 인증서를 trusted root 로
워크로드에 배포할 수 있습니다.

다음 그래프는 두개의 클러스터가 포함된 메시에서 권장되는 CA 계층을 보여줍니다.

![image](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/ca-hierarchy.svg)

이 작업은 어떻게 istio CA 를 위한 인증서와 키를 생성하고 플러그인 할 수 있는지 보여줍니다. 
아래 작업들은 개별 클러스터에 인증서와 키를 프로비전 할 수 있도록 반복될 수 있습니다.

## 인증서와 키를 클러스터에 Plug in 하기
> 프로덕션에서는 production-ready CA 사용하기 (ex. Hashicorp Vault) 

Istio root CA 를 사용자가 지정할 수 있다.