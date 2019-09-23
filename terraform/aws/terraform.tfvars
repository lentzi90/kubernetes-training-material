#Global Vars
aws_cluster_name = "mrg-workshop"
AWS_SSH_KEY_NAME="lennart@elrond"
AWS_DEFAULT_REGION="eu-west-3"

#VPC Vars
aws_vpc_cidr_block = "10.250.192.0/18"
aws_cidr_subnets_private = ["10.250.192.0/24","10.250.193.0/24","10.250.194.0/24"]
aws_cidr_subnets_public = ["10.250.224.0/24","10.250.225.0/24","10.250.226.0/24"]

#Bastion Host
aws_bastion_size = "t3.small"


#Kubernetes Cluster

aws_kube_master_num = 1
aws_kube_master_size = "t3.medium"

aws_etcd_num = 0
aws_etcd_size = "t3.medium"

aws_kube_worker_num = 2
aws_kube_worker_size = "t3.small"

#Settings AWS ELB

aws_elb_api_port = 6443
k8s_secure_api_port = 6443

default_tags = {
#  Env = "devtest"
#  Product = "kubernetes"
}

inventory_file = "../../../inventory/hosts"
