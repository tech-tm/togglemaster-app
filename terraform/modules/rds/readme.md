## Inicialização dos Bancos PostgreSQL (RDS)

## Problema

O Terraform cria apenas as instâncias do Amazon RDS e os bancos (`auth_db`, `flags_db` e `targeting_db`), porém **não cria as tabelas** utilizadas pelos microsserviços.

Os scripts SQL de criação encontram-se em:

```text
auth-service/db/init.sql
flag-service/db/init.sql
targeting-service/db/init.sql
```

Sem executar esses scripts, os serviços apresentam erros como:

```text
ERROR: relation "api_keys" does not exist
ERROR: relation "flags" does not exist
ERROR: relation "targeting_rules" does not exist
```

---

# Solução adotada

Foi criado um conjunto de **Kubernetes Jobs** responsáveis por inicializar automaticamente cada banco de dados.

Cada ConfigMap incorpora o conteúdo do respectivo `init.sql` e o Job executa:

```bash
psql -h <RDS_ENDPOINT> \
     -U $POSTGRES_USER \
     -d <DATABASE> \
     -f /sql/init.sql
```

Como todos os scripts utilizam:

```sql
CREATE TABLE IF NOT EXISTS
```

a execução é **idempotente**, podendo ser repetida sem causar erros.

---

# Ordem correta de deploy

## 1 - Provisionar infraestrutura

Executar normalmente o Terraform para criar:

- Amazon RDS
- ElastiCache
- DynamoDB

```bash
cd terraform/rds

terraform init
terraform apply
```

---

## 2 - Inicializar os bancos

Aplicar os Jobs responsáveis pela criação das tabelas:

Resultado esperado:

```text
auth-db-init        Complete
flag-db-init        Complete
targeting-db-init   Complete
```

Também é possível validar os logs:

```bash
kubectl logs job/auth-db-init -n togglemaster
kubectl logs job/flag-db-init -n togglemaster
kubectl logs job/targeting-db-init -n togglemaster
```

---

## 3 - Fazer o deploy da aplicação

Após os bancos estarem inicializados:

```bash
kubectl apply -k k8s
```

ou reiniciar os deployments:

```bash
kubectl rollout restart deployment -n togglemaster
```

---

# Reexecutando os Jobs

Caso seja necessário executar novamente os scripts:

```bash
kubectl delete jobs \
auth-db-init \
flag-db-init \
targeting-db-init \
-n togglemaster
```

Depois:

```bash
kubectl apply -k terraform/rds/db-init
```

---

# Observações

- Os Jobs apenas inicializam o esquema do banco.
- Eles não removem dados existentes.
- A execução é segura graças ao uso de `CREATE TABLE IF NOT EXISTS`.
- Caso novas tabelas sejam adicionadas futuramente, basta atualizar os respectivos arquivos `init.sql` e reaplicar os Jobs.

---