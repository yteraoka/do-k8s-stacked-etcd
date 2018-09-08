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

## Dashboard のインストール

playbook とは関係ないが、メモ

CLI だけよりも Web UI があった方が便利なので [dashboard](https://github.com/kubernetes/dashboard/) をインストールする方法

## kubectl apply でインストール

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```

## アクセスするためのユーザーを作成

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
apiVersion: rbac.authorization.k8s.io/v1beta1
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

`kubectl apply` で適用すると admin-user というサービスアカウントが作成され、それに
cluster-admin role がセットされる

```
kubectl apply -f admin-user.yaml
```

Dashboard にアクセスするにはローカル PC で `kubectl proxy` を実行し、その proxy を使う

[http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

アクセスするには認証が必要なので今作った admin-user の token を使う

```
kubectl get serviceaccounts admin-user -o yaml -n kube-system
```

```
kubectl get secret admin-user-token-x8r9b -o yaml -n kube-system
```

これで取得できる secret は base64 encoded なので decode する必要がある

```
kubectl get secret admin-user-token-x8r9b -o json -n kube-system | jq -r .data.token | sed 's/\n//' | base64 -d
```

もしくは

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

