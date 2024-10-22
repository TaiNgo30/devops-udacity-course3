helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install prj3 bitnami/postgresql --set primary.persistence.enabled=false
POSTGRESQL=coworking-prj-postgresql
POSTGRES_PASSWORD=$(kubectl get secret coworking-prj-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl port-forward svc/"$POSTGRESQL" 5432:5432 &
PGPASSWORD="$POSTGRES_PASSWORD"  psql -U postgres -d postgres -h 127.0.0.1 -a -f db/1_create_tables.sql
PGPASSWORD="$POSTGRES_PASSWORD"  psql -U postgres -d postgres -h 127.0.0.1 -a -f db/2_seed_users.sql
PGPASSWORD="$POSTGRES_PASSWORD"  psql -U postgres -d postgres -h 127.0.0.1 -a -f db/3_seed_tokens.sql