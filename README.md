# DigitalOcean に kubeadm で k8s クラスタを作成する ansible playbook

ControlPlane サーバー3台で etcd のクラスタも相乗りさせる Kubernetes クラスタの構築

DigitalOcean の dynamic inventory を使用するため、環境変数 `DO_API_TOKEN` または
`DO_API_KEY` をセットする必要があります。また、サーバー (droplet) の作成は ansible では
行いません。Web Console でも doctl コマンドで作成しても良い。

OS はひとまず CentOS 7

## サーバー等の準備 (Terraform)

Terraform でサーバー、ロードバランサー、DNS をセットアップ

(doctl だとやっぱり面倒なので)

```
cd terraform
bash init.sh
terraform plan -out tfout
terraform apply tfout
```

使い終わった後の削除も楽

```
terraform destroy
```

CPU の数は最低2つ必要とされており、足りていない場合は kubectl init でエラーとなるが、テスト用などで無視したい場合は `--ignore-preflight-errors=NumCPU` をセットする

<!---

```
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
```

```
# kubeadm init --config /tmp/kubeadm-config.yaml --ignore-preflight-errors=NumCPU
[init] Using Kubernetes version: v1.13.1
[preflight] Running pre-flight checks
        [WARNING NumCPU]: the number of available CPUs 1 is less than the required 2
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [cp1 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local k8s-api.do.teraoka.me k8s-api.do.teraoka.me] and IPs [10.96.0.1 178.128.218.44]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [cp1 localhost] and IPs [178.128.218.44 127.0.0.1 ::1]
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [cp1 localhost] and IPs [178.128.218.44 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "admin.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[kubelet-check] Initial timeout of 40s passed.
[apiclient] All control plane components are healthy after 50.614228 seconds
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.13" in namespace kube-system with the configuration for the kubelets in the cluster
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "cp1" as an annotation
[mark-control-plane] Marking the node cp1 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node cp1 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: 381xdy.2p79kl2lbqnvp58b
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join k8s-api.do.teraoka.me:443 --token 381xdy.2p79kl2lbqnvp58b --discovery-token-ca-cert-hash sha256:f26de6f3117c0ab4730f4e7294a7f59415d365dbeb5c0829672b970696756799

```

```
# kubeadm join k8s-api.do.teraoka.me:443 --token 3dvqss.mgzbedpf0yxy127b --discovery-token-ca-cert-hash sha256:f374c3dfd972c78ddc479c9f4c3b1452b3417d26d65916d671157be06b5f18be --experimental-control-plane
[preflight] Running pre-flight checks
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[discovery] Trying to connect to API Server "k8s-api.do.teraoka.me:443"
[discovery] Created cluster-info discovery client, requesting info from "https://k8s-api.do.teraoka.me:443"
[discovery] Requesting info from "https://k8s-api.do.teraoka.me:443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "k8s-api.do.teraoka.me:443"
[discovery] Successfully established connection with API Server "k8s-api.do.teraoka.me:443"
[join] Reading configuration from the cluster...
[join] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[join] Running pre-flight checks before initializing the new control plane instance
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [cp2 localhost] and IPs [178.128.22.228 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [cp2 localhost] and IPs [178.128.22.228 127.0.0.1 ::1]
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [cp2 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local k8s-api.do.teraoka.me k8s-api.do.teraoka.me] and IPs [10.96.0.1 178.128.22.228]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] valid certificates and keys now exist in "/etc/kubernetes/pki"
[certs] Using the existing "sa" key
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Using existing up-to-date kubeconfig file: "/etc/kubernetes/admin.conf"
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[etcd] Checking Etcd cluster health
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Activating the kubelet service
[tlsbootstrap] Waiting for the kubelet to perform the TLS Bootstrap...
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "cp2" as an annotation
[etcd] Announced new etcd member joining to the existing etcd cluster
[etcd] Wrote Static Pod manifest for a local etcd instance to "/etc/kubernetes/manifests/etcd.yaml"
[uploadconfig] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet-check] Initial timeout of 40s passed.
[mark-control-plane] Marking the node cp2 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node cp2 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]

This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Master label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.

To start administering your cluster from this node, you need to run the following as a regular user:

        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.
```

```
# kubectl get nodes
NAME   STATUS   ROLES    AGE    VERSION
cp1    Ready    master   168m   v1.13.1
cp2    Ready    master   12m    v1.13.1
cp3    Ready    master   50s    v1.13.1
```

```
# kubeadm join k8s-api.do.teraoka.me:443 --token 3dvqss.mgzbedpf0yxy127b --discovery-token-ca-cert-hash sha256:f374c3dfd972c78ddc479c9f4c3b1452b3417d26d65916d671157be06b5f18be
[preflight] Running pre-flight checks
        [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[discovery] Trying to connect to API Server "k8s-api.do.teraoka.me:443"
[discovery] Created cluster-info discovery client, requesting info from "https://k8s-api.do.teraoka.me:443"
[discovery] Requesting info from "https://k8s-api.do.teraoka.me:443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "k8s-api.do.teraoka.me:443"
[discovery] Successfully established connection with API Server "k8s-api.do.teraoka.me:443"
[join] Reading configuration from the cluster...
[join] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet] Downloading configuration for the kubelet from the "kubelet-config-1.13" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Activating the kubelet service
[tlsbootstrap] Waiting for the kubelet to perform the TLS Bootstrap...
[patchnode] Uploading the CRI Socket information "/var/run/dockershim.sock" to the Node API object "worker-0" as an annotation

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the master to see this node join the cluster.
```

--->

## サーバー等の準備 (doctl)

doctl で各リソースを作成

`--ssh-keys` の値は例

### control-plane と etcd 相乗りサーバーを3台作成

それぞれ `first`, `second`, `thrid` という tag をつけることで、ansible では group として扱える

```
doctl compute droplet create cp1 \
  --enable-monitoring \
  --enable-private-networking \
  --image centos-7-x64 \
  --region sgp1 \
  --size s-1vcpu-3gb \
  --ssh-keys 16797382,18482899 \
  --tag-names k8s,control-plane,first
```

```
doctl compute droplet create cp2 \
  --enable-monitoring \
  --enable-private-networking \
  --image centos-7-x64 \
  --region sgp1 \
  --size s-1vcpu-3gb \
  --ssh-keys 16797382,18482899 \
  --tag-names k8s,control-plane,second
```

```
doctl compute droplet create cp3 \
  --enable-monitoring \
  --enable-private-networking \
  --image centos-7-x64 \
  --region sgp1 \
  --size s-1vcpu-3gb \
  --ssh-keys 16797382,18482899 \
  --tag-names k8s,control-plane,third
```

### control-plane タグを持つ droplet を forward 先にした load balancer を作成する

```
doctl compute load-balancer create \
  --name k8s-api \
  --region sgp1 \
  --forwarding-rules entry_protocol:tcp,entry_port:443,target_protocol:tcp,target_port:6443 \
  --health-check protocol:tcp,port:6443 \
  --tag-name control-plane
```

Load Balancer は構築に数分かかります

```
doctl compute load-balancer list
```

で Status が active になるまで待つ、そうすると IP Address も決まるので DNS 登録する

### DNS レコード設定

Ansible playbook 実行時に `load_balancer_dns` 変数で渡す DNS レコードを設定

```
doctl compute domain records create example.com \
  --record-name k8s-api \
  --record-ttl 60 \
  --record-type A \
  --record-data xxx.xxx.xxx.xxx
```

レコードがすでに存在する場合は、delete して create するか update コマンドを使います

### worker node サーバーの作成

```
doctl compute droplet create worker1 worker2 worker3 \
  --enable-monitoring \
  --enable-private-networking \
  --image centos-7-x64 \
  --region sgp1 \
  --size s-1vcpu-2gb \
  --ssh-keys 16797382,18482899 \
  --tag-names k8s,worker \
  --wait
```

## Ansible Playbook の実行

`inventory/digital_ocean.py` で必要な module のインストール

```
pip install requests
```

```
ansible-playbook site.yml -e load_balancer_dns=xxx.example.com
```

## worker node のクラスタへの追加

`kubeadm init` 時に join 用の token が表示されるが、ansible では出力していないため、どれかの
コントロールプレーン node で別途 `kubeadm token create` を実行して取得する
作成する

`--discovery-token-ca-cert-hash` で指定する hash は次のコマンドで生成できる

```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
  | openssl rsa -pubin -outform der 2>/dev/null \
  | openssl dgst -sha256 -hex | sed 's/^.* //'
```

これらを用いて worker node で次のようなコマンドを実行する

```
kubeadm join xxx.example.com:443 --token e69t47.k98pkcidzvgexwbz \
  --discovery-token-ca-cert-hash \
   sha256:b0e28afb25529ad1405d6adecd4a154ace51b6245ff59477f5ea465e221936de
```

## Windows への kubectl のインストール

https://kubernetes.io/docs/tasks/tools/install-kubectl/

[Chocolatey](https://chocolatey.org/) や [Powershell Gallery](https://www.powershellgallery.com/) からもインストールできるようだが、git-bash 使いなので curl でダウンロードする

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.13.1/bin/windows/amd64/kubectl.exe
```

## Dashboard のインストール

playbook とは関係ないが、メモ

CLI だけよりも Web UI があった方が便利なので [dashboard](https://github.com/kubernetes/dashboard/) をインストールする方法

### kubectl apply でインストール

#### Recommended

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
```

<!---
実行した際の出力

```
secret/kubernetes-dashboard-certs created
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created
```
--->

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

#### Alternative (TLS (https およびクライアント認証) が不要)

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/alternative/kubernetes-dashboard.yaml
```

http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard:/proxy/

### Dashboard にアクセスするためのユーザーを作成

Creating sample user
https://github.com/kubernetes/dashboard/wiki/Creating-sample-user

`admin-user.yaml` を次の内容で作成

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

`kubectl apply -f admin-user.yaml` で適用すると admin-user というサービスアカウントが作成され、
それに cluster-admin role がセットされる

```
kubectl apply -f admin-user.yaml
```

Dashboard にアクセスするにはローカル PC で `kubectl proxy` を実行し、その proxy を使う

[http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

アクセスするには認証が必要なので今作った admin-user の token を使う

```
kubectl get serviceaccounts admin-user -o yaml -n kube-system
```

次のコマンドで secret 名が取得できる

```
secret_name=$(kubectl get serviceaccounts admin-user -o json -n kube-system | jq -r .secrets[].name)
```

取得した secret 名で secret を取得する

```
kubectl get secret ${secret_name} -o yaml -n kube-system
```

これで取得できる secret は base64 encoded なので decode する必要がある

```
kubectl get secret ${secret_name} -o json -n kube-system \
  | jq -r .data.token | sed 's/\n//' | base64 -d
```

もしくは

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

