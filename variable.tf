variable "myvpccidr"{
  default = "10.0.0.0/16"
}

variable "myregion"{
   default = "us-east-1"
}

variable "mysubnetcidr"{
    default = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24","10.0.5.0/24"]
}

variable "ec2type"{
    type = list
    default = ["t2.micro", "t2.small", "t3.micro", "t3.small", "t3.medium"]
}

variable "ingress_rules" {
    type = list(number)
    description = "lists of ingress ports"
    default = [8200, 8201,8300, 9200, 9500]
}





