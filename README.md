# Coworking Space Service Extension

#### Local Environment
1. Python Environment - run Python 3.10 applications and install Python dependencies via `pip`
2. Docker CLI - build and run Docker images locally
3. `kubectl` - run commands against a Kubernetes cluster
4. `helm` - apply Helm Charts to a Kubernetes cluster

#### Remote Resources
1. AWS CodeBuild - build Docker images remotely
2. AWS ECR - host Docker images
3. Kubernetes Environment with AWS EKS - run applications in k8s
4. AWS CloudWatch - monitor activity and logs in EKS
5. GitHub - pull and clone code

### Setup
#### 1. Configure a Database
Set up a Postgres database using a Helm Chart.

1. Set up Bitnami Repo
```bash
helm repo add https://charts.bitnami.com/bitnami
helm repo update
```

2. Install PostgreSQL Helm Chart
```
helm install coworking-prj bitnami/postgresql --set primary.persistence.enabled=false
```

```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default coworking-prj-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo $POSTGRES_PASSWORD
```

<sup><sub>* The instructions are adapted from [Bitnami's PostgreSQL Helm Chart](https://artifacthub.io/packages/helm/bitnami/postgresql).</sub></sup>

3. Test Database Connection

* Connecting Via Port Forwarding
```bash
kubectl port-forward --namespace default svc/coworking-prj-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```

* Connecting Via a Pod
```bash
kubectl exec -it <POD_NAME> bash
PGPASSWORD="<PASSWORD HERE>" psql postgres://postgres@<SERVICE_NAME>:5432/postgres -c <COMMAND_HERE>
```

4. Run Seed Files
We will need to run the seed files in `db/` in order to create the tables and populate them with data.

```bash
kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < <FILE_NAME.sql>
```

### 2. Running the Analytics Application Locally
In the `analytics/` directory:

1. Install dependencies
```bash
pip install -r requirements.txt
```
2. Run the application (see below regarding environment variables)
```bash
<ENV_VARS> python app.py
```

There are multiple ways to set environment variables in a command. They can be set per session by running `export KEY=VAL` in the command line or they can be prepended into your command.

* `DB_USERNAME`
* `DB_PASSWORD`
* `DB_HOST` (defaults to `127.0.0.1`)
* `DB_PORT` (defaults to `5432`)
* `DB_NAME` (defaults to `postgres`)

If we set the environment variables by prepending them, it would look like the following:
```bash
DB_USERNAME=username_here DB_PASSWORD=password_here python app.py
```
The benefit here is that it's explicitly set. However, note that the `DB_PASSWORD` value is now recorded in the session's history in plaintext. There are several ways to work around this including setting environment variables in a file and sourcing them in a terminal session.

3. Verifying The Application
* Generate report for check-ins grouped by dates
`curl <BASE_URL>/api/reports/daily_usage`

* Generate report for check-ins grouped by users
`curl <BASE_URL>/api/reports/user_visits`

## Set up CodeBuild
1. Create a CodeBuild job, take your github personal access token and embed it in Secret Managers.
2. We have an buildspec.yml file that include build stage, you can refer it.
3. Setup GithubHook - your token must have hooks permission.
3. For requirments of CodeBuild, you have to input environments required to your scret.
4. When you already had a CodeBuild job, in IAM Role will have a service role. You have to attach AmazonEC2ContainerRegistryPowerUser policy for pushing artifacts to the image repository ECR.

## Set up CloudWatch
1. Create trust-policy.json and run the following command to associate the OIDC provider with your EKS cluster, create an IAM Role for CloudWatch Agent, create the Service Account for CloudWatch Agent and finally install the CloudWatch Add-On.
2. Run this:
```bash
eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster coworking-cluster --approve
aws iam create-role --role-name eks-cloudwatch-role --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name eks-cloudwatch-role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
eksctl create iamserviceaccount \
  --name cloudwatch-agent \
  --namespace kube-system \
  --cluster coworking-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --approve \
  --override-existing-serviceaccounts
aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name coworking-cluster
```
3. Ping the service so that the container having logs and sent to Log Groups:
For example: 
```bash
curl a4dcc5a890fb64db090856a3979bda82-1741244717.us-east-1.elb.amazonaws.com:5153/health_check
curl a4dcc5a890fb64db090856a3979bda82-1741244717.us-east-1.elb.amazonaws.com:5153/readiness_check
```
