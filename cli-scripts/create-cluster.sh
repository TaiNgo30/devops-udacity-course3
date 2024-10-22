eksctl create cluster --name coworking-cluster --region us-east-1 --nodegroup-name coworking-nodes --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 2
aws eks --region us-east-1 update-kubeconfig --name coworking-cluster
