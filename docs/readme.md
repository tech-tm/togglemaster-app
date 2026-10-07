# Documentacao de Infraestrutura e Execucao

obs: utilizado podman mas é a mesma coisa com docker.

```bash
podman-compose up --build -d

```


## Orquestração no Kubernetes (Amazon EKS)

Para manter a separação de responsabilidades, os manifestos de implantação estão isolados no diretório kubernetes. A arquitetura utiliza o Kustomize para gerir a substituição dinâmica das imagens dos contentores e a criação da infraestrutura declarativa.

### Geração de Credenciais Seguras

O projeto centraliza as variáveis sensíveis num ficheiro .env na raiz do repositório. O script de automação lê este ficheiro para provisionar as credenciais do Terraform para os bancos de dados RDS e os Secrets do Kubernetes em base64, impedindo a exposição de dados no controlo de versões.

Certifique-se de que o ficheiro .env está preenchido e que os valores não contêm aspas. Conceda permissão de execução e inicie o script:

```bash
chmod +x gerar_secrets.sh
./gerar_secrets.sh

```

O script criará o ficheiro terraform/rds/secrets.auto.tfvars e o manifesto kubernetes/secret.yaml.

### Conexão e Implantação no Cluster

Após a infraestrutura estar ativa, atualize a configuração do cliente local para estabelecer comunicação com o plano de controlo do EKS:

```bash
aws eks update-kubeconfig --region us-east-1 --name togglemaster-cluster

```

Edite o ficheiro kubernetes/kustomization.yaml para inserir o Account ID correto na secção de imagens. Em seguida, aplique todos os recursos simultaneamente utilizando a flag do Kustomize:

```bash
kubectl apply -k kubernetes/

```

Caso os pods já estejam em execução e seja necessário forçar o recarregamento de novas variáveis provenientes do ConfigMap ou do Secret, execute um reinício controlado para substituir os contentores sem tempo de inatividade:

```bash
kubectl rollout restart deployment auth-service flag-service targeting-service evaluation-service analytics-service

```

## Replicação no Ambiente Restrito (AWS Academy)

Para reproduzir esta implantação com sucesso na infraestrutura do AWS Academy utilizando a `LabRole`, é mandatório seguir a arquitetura validada e os contornos técnicos listados abaixo.

### 1. Parâmetros Críticos do Cluster (EKS & Node Group)
O cluster EKS e o grupo de nós gerenciados devem ser criados via Console da AWS ou CLI utilizando estritamente as seguintes definições de infraestrutura para evitar bloqueios de permissão do IAM:

```json
{
  "cluster": {
    "name": "togglemaster-eks",
    "region": "us-east-1",
    "kubernetesVersion": "1.36",
    "iamRole": "LabRole",
    "authenticationMode": "EKS_API",
    "clusterAdministratorAccess": true
  },
  "nodeGroup": {
    "name": "togglemaster-ng",
    "nodeIamRole": "LabRole",
    "capacityType": "ON_DEMAND",
    "instanceTypes": ["t3.medium"],
    "scaling": {
      "desiredSize": 2,
      "minSize": 1,
      "maxSize": 4
    },
    "remoteAccess": {
      "enabled": false
    }
  }
}

```


## Instruções para Testes de Escalabilidade

Para realizar os testes de escalabilidade do projeto, siga os passos abaixo em um ambiente com `aws-cli`, `kubectl` e `go` instalados.

### 1. Configuração de Rede (Security Group)

A cada nova sessão da AWS Academy, os IPs dos nós e as portas expostas podem mudar. É necessário liberar a porta do `NodePort` atual no Security Group.

1. Identifique a porta de serviço atual:
`kubectl get svc ingress-nginx-controller -n togglemaster`
2. Identifique o Security Group dos seus nós:
`aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" --output text`
3. Libere a porta identificada (exemplo para porta 32196):
`aws ec2 authorize-security-group-ingress --region us-east-1 --group-id <SEU_ID_DO_SG> --protocol tcp --port 32196 --cidr 0.0.0.0/0`

### 2. Instalação da Ferramenta de Carga (hey)

O script `escalabilidade.sh` utiliza o `hey` para geração de carga. Certifique-se de tê-lo instalado:

1. Instale via Go:
`go install [github.com/rakyll/hey@latest](https://github.com/rakyll/hey@latest)`
2. Adicione ao seu PATH (se necessário):
`echo 'export PATH=$PATH:/home/$USER/go/bin' >> ~/.bashrc && source ~/.bashrc`

### 3. Execução do Teste de Escalabilidade

O script `escalabilidade.sh` automatiza a descoberta do endpoint, a geração de carga e o monitoramento do HPA e dos nós.

1. Navegue até a pasta de scripts:
`cd ~/estudo/projeto2/scripts`
2. Garanta permissão de execução:
`chmod +x escalabilidade.sh`
3. Execute o teste:
`./escalabilidade.sh`

O script coletará os dados automaticamente, monitorará o ciclo de vida dos pods durante a carga e gerará um relatório final no terminal.

---

# Security Groups necessários

## 1. EKS (Worker Nodes)

O Security Group dos Worker Nodes deve permitir acesso ao NodePort utilizado pelo NGINX Ingress.

Exemplo:

| Tipo       | Protocolo | Porta | Origem    |
| ---------- | --------- | ----- | --------- |
| Custom TCP | TCP       | 32594 | 0.0.0.0/0 |

Caso utilize HTTPS:

| Tipo | Porta |
| ---- | ----- |
| TCP  | 31079 |

Esse foi exatamente o ajuste que você fez para conseguir acessar:

```
http://<IP_DO_NODE>:32594
```

---

## 2. RDS PostgreSQL

Cada instância RDS deve permitir conexões vindas do Security Group do EKS.

Inbound:

| Tipo       | Porta | Origem                |
| ---------- | ----- | --------------------- |
| PostgreSQL | 5432  | Security Group do EKS |

Não é recomendado liberar:

```
0.0.0.0/0
```

O ideal é permitir apenas o Security Group associado aos Worker Nodes.

Fluxo:

```
Pods
   │
   ▼
RDS PostgreSQL
```

---

## 3. ElastiCache Redis

Inbound:

| Tipo | Porta | Origem                |
| ---- | ----- | --------------------- |
| TCP  | 6379  | Security Group do EKS |

Fluxo:

```
Pods
   │
   ▼
Redis
```

---

## 4. DynamoDB

O DynamoDB **não utiliza Security Groups**, porque é um serviço gerenciado acessado via API HTTPS.

Os Pods precisam apenas de:

* credenciais AWS válidas (IAM Role ou Access Key);
* acesso de saída à Internet ou a um **VPC Endpoint** para DynamoDB.

Fluxo:

```
Pods
   │
 HTTPS 443
   │
   ▼
DynamoDB
```

---

## 5. AWS SQS (caso utilizado)

Assim como o DynamoDB:

* não possui Security Group;
* utiliza HTTPS (porta 443);
* requer apenas IAM e conectividade.

---

## Resumo

| Serviço           | Porta     | Security Group                  |
| ----------------- | --------- | ------------------------------- |
| Ingress NodePort  | 32594     | Liberar Internet → Worker Nodes |
| PostgreSQL RDS    | 5432      | Permitir SG do EKS              |
| ElastiCache Redis | 6379      | Permitir SG do EKS              |
| DynamoDB          | HTTPS 443 | Não utiliza SG                  |
| SQS               | HTTPS 443 | Não utiliza SG                  |

---

### Arquitetura de rede:

* **Security Group do EKS**: recebe tráfego externo nas portas do Ingress (32594/31079) e faz conexões de saída.
* **Security Group do RDS**: permite entrada apenas do SG do EKS na porta 5432.
* **Security Group do ElastiCache**: permite entrada apenas do SG do EKS na porta 6379.
* **DynamoDB e SQS**: acessados via HTTPS com autenticação IAM, sem Security Groups próprios.
