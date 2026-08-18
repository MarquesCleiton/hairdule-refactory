# 🛡️ Hairdule 2.0 — Guia Mestre de Políticas IAM de Menor Privilégio (*Least Privilege*)

> **Projeto:** Hairdule 2.0 — SaaS de Agendamentos para Estabelecimentos de Beleza  
> **Objetivo:** Fornecer o conjunto completo de políticas IAM reutilizáveis, modulares e estritamente limitadas aos recursos necessários para o provisionamento via SST v4 e CI/CD GitFlow (Fases 01 a 27).  
> **Última Atualização:** 2026-08-12  
> **Segurança:** ZERO privilégios genéricos (`Action: "*"`). Restrições por ARNs específicos (`Resource: "arn:aws:...:hairdule-*"`), `iam:PassRole` restrito a serviços autorizados e **DENY explícito** em gerenciamento de usuários IAM.

---

## 🏛️ Visão Geral da Arquitetura de Permissões IAM

Em vez de conceder `AdministratorAccess` ou usar políticas monolíticas com wildcards perigosos, o controle de acesso do Hairdule 2.0 é dividido em **6 Políticas Modulares Menores (Customer Managed Policies)**. 

Cada política atende a uma camada funcional bem definida da infraestrutura:

```
┌─────────────────────────────────────────────────────────────────────────┐
│              🤖 USUÁRIO DE CI/CD (github-actions-staging / prod)        │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
     ┌───────────────────────────────┼───────────────────────────────┐
     ▼                               ▼                               ▼
1. HairdulePolicySSTCore    2. HairdulePolicyNetworkSecurity 3. HairdulePolicyAuthCognito
   (Bootstrap SST & SSM)       (VPC, EC2, KMS & Logs)          (Cognito & Secrets Manager)
     │                               │                               │
     ▼                               ▼                               ▼
4. HairdulePolicyDatabase   5. HairdulePolicyServerlessCDN   6. HairdulePolicyIAMGovernance
   (Aurora PostgreSQL RDS)     (Lambda, API GW, S3, CDN)       (Roles & Deny User Ops)
```

---

## 📋 Tabela Resumo das Políticas IAM

| Política IAM | Módulo / Fases Cobertas | Recursos AWS Permitidos |
|---|---|---|
| **1. `HairdulePolicySSTCore`** | Bootstrap SST v4 (Todas as Fases) | SSM Parameter Store (`/sst/*`), STS `GetCallerIdentity` |
| **2. `HairdulePolicyNetworkSecurity`** | Fases 01 e 02 | VPC, Subnets, IGW, NAT Gateway, Security Groups, CloudMap Service Discovery & Route 53, KMS Keys (`alias/hairdule-*`), CloudWatch Logs |
| **3. `HairdulePolicyAuthCognito`** | Fase 03, 09, 10 | Cognito User Pools (`hairdule-user-pool-*`), UserPoolClients, IdentityProviders, Secrets Manager (`hairdule/*`) |
| **4. `HairdulePolicyDatabase`** | Fases 02, 04, 05 | RDS DB Subnet Groups, Aurora Serverless v2 Cluster, DB Instances, Parameter Groups (`hairdule-*`) |
| **5. `HairdulePolicyServerlessCDN`** | Fases 06, 07, 08, 09-27 | Lambdas Python, Lambda Layers, API Gateway HTTP APIs, WAF WebACLs, Buckets S3 (`hairdule-*`), CloudFront CDN, EventBridge Scheduler |
| **6. `HairdulePolicyIAMGovernance`** | Governança Global | IAM Roles (`hairdule-*`), `iam:PassRole` restrito a serviços AWS confiáveis, **DENY explícito** em criação/exclusão de usuários IAM |

---

## 📄 JSON Completo de Cada Política IAM

---

### 1. `HairdulePolicySSTCore`
> **Finalidade:** Permite ao CLI do SST v4 gerenciar estados de bootstrap no SSM Parameter Store e autenticar o runner.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SSMDescribeParametersAccountLevel",
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeParameters"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSTBootstrapSSM",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:PutParameter",
        "ssm:DeleteParameter",
        "ssm:AddTagsToResource",
        "ssm:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:ssm:us-east-1:*:parameter/sst/*",
        "arn:aws:ssm:us-east-1:*:parameter/sst"
      ]
    },
    {
      "Sid": "SSTStateAndAssetsS3Bucket",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::sst-*",
        "arn:aws:s3:::sst-*/*"
      ]
    },
    {
      "Sid": "STSCallerIdentity",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 2. `HairdulePolicyNetworkSecurity` (Fases 01 e 02)
> **Finalidade:** Provisionamento restrito de rede (VPC, Subnets, NAT, Firewalls), Criptografia em repouso (Chaves KMS) e logs do CloudWatch.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCNetworkManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "ec2:RunInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeImages",
        "ec2:DescribeVolumes",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyInstanceAttribute",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSEncryptionKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:EnableKeyRotation",
        "kms:DisableKeyRotation",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:UpdateAlias",
        "kms:ListAliases",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:GenerateDataKey*",
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsManagement",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        "logs:TagResource",
        "logs:UntagResource",
        "logs:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ServiceDiscoveryAndRoute53Management",
      "Effect": "Allow",
      "Action": [
        "servicediscovery:CreatePrivateDnsNamespace",
        "servicediscovery:CreatePublicDnsNamespace",
        "servicediscovery:CreateHttpNamespace",
        "servicediscovery:DeleteNamespace",
        "servicediscovery:GetNamespace",
        "servicediscovery:ListNamespaces",
        "servicediscovery:UpdatePrivateDnsNamespace",
        "servicediscovery:UpdatePublicDnsNamespace",
        "servicediscovery:UpdateHttpNamespace",
        "servicediscovery:CreateService",
        "servicediscovery:DeleteService",
        "servicediscovery:GetService",
        "servicediscovery:ListServices",
        "servicediscovery:UpdateService",
        "servicediscovery:GetOperation",
        "servicediscovery:TagResource",
        "servicediscovery:UntagResource",
        "servicediscovery:ListTagsForResource",
        "servicediscovery:GetInstance",
        "servicediscovery:RegisterInstance",
        "servicediscovery:DeregisterInstance",
        "servicediscovery:DiscoverInstances",
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:ListHostedZonesByName",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "route53:ListResourceRecordSets",
        "route53:ChangeTagsForResource",
        "route53:ListTagsForResource",
        "route53:GetHostedZoneCount"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 3. `HairdulePolicyAuthCognito` (Fase 03)
> **Finalidade:** Gerenciamento de identidades no AWS Cognito (User Pools, App Clients, Identity Providers) e cofres no AWS Secrets Manager.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CognitoUserPoolManagement",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:CreateUserPool",
        "cognito-idp:DeleteUserPool",
        "cognito-idp:DescribeUserPool",
        "cognito-idp:UpdateUserPool",
        "cognito-idp:GetUserPoolMfaConfig",
        "cognito-idp:SetUserPoolMfaConfig",
        "cognito-idp:CreateUserPoolClient",
        "cognito-idp:DeleteUserPoolClient",
        "cognito-idp:DescribeUserPoolClient",
        "cognito-idp:UpdateUserPoolClient",
        "cognito-idp:CreateIdentityProvider",
        "cognito-idp:DeleteIdentityProvider",
        "cognito-idp:DescribeIdentityProvider",
        "cognito-idp:UpdateIdentityProvider",
        "cognito-idp:TagResource",
        "cognito-idp:UntagResource",
        "cognito-idp:ListTagsForResource"
      ],
      "Resource": "arn:aws:cognito-idp:us-east-1:*:userpool/*"
    },
    {
      "Sid": "SecretsManagerManagement",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:PutResourcePolicy",
        "secretsmanager:DeleteResourcePolicy",
        "secretsmanager:UpdateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:hairdule/*"
    }
  ]
}
```

---

### 4. `HairdulePolicyDatabase` (Fase 04)
> **Finalidade:** Criar e gerenciar o cluster Aurora PostgreSQL Serverless v2, Subnet Groups, Instâncias de Banco de Dados e Grupos de Parâmetros.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AuroraPostgreSQLManagement",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:DescribeDBSubnetGroups",
        "rds:ModifyDBSubnetGroup",
        "rds:CreateDBCluster",
        "rds:DeleteDBCluster",
        "rds:DescribeDBClusters",
        "rds:DescribeGlobalClusters",
        "rds:ModifyDBCluster",
        "rds:StopDBCluster",
        "rds:StartDBCluster",
        "rds:RestoreDBClusterFromSnapshot",
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:CreateDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:ModifyDBParameterGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "rds:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:rds:us-east-1:*:subgrp:hairdule-*",
        "arn:aws:rds:us-east-1:*:cluster:hairdule-*",
        "arn:aws:rds:us-east-1:*:db:*",
        "arn:aws:rds:us-east-1:*:pg:hairdule-*",
        "arn:aws:rds::*:global-cluster:*"
      ]
    },
    {
      "Sid": "RDSServiceLinkedRoleCreation",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "rds.amazonaws.com"
        }
      }
    },
    {
      "Sid": "EventBridgeAndLambdaAutoStopManagement",
      "Effect": "Allow",
      "Action": [
        "events:PutRule",
        "events:DeleteRule",
        "events:DescribeRule",
        "events:ListRules",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:ListTargetsByRule",
        "events:TagResource",
        "events:UntagResource",
        "events:ListTagsForResource",
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:ListVersionsByFunction",
        "lambda:ListEventSourceMappings",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:GetPolicy",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:InvokeFunction",
        "lambda:TagResource",
        "lambda:UntagResource"
      ],
      "Resource": [
        "arn:aws:events:us-east-1:*:rule/hairdule-*",
        "arn:aws:lambda:us-east-1:*:function:hairdule-*"
      ]
    }
  ]
}
```

---

### 5. `HairdulePolicyServerlessCDN` (Fases 05 a 27)
> **Finalidade:** Gerenciar Lambdas Python (Microsserviços), Lambda Layers (`hairdule-shared`), API Gateway, WAF, S3 Buckets, CloudFront CDN e EventBridge Scheduler.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaFunctionAndLayerManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:ListVersionsByFunction",
        "lambda:ListEventSourceMappings",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:GetPolicy",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishLayerVersion",
        "lambda:DeleteLayerVersion",
        "lambda:GetLayerVersion",
        "lambda:PublishVersion",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:InvokeFunction",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:ListTags"
      ],
      "Resource": [
        "arn:aws:lambda:us-east-1:*:function:hairdule-*",
        "arn:aws:lambda:us-east-1:*:layer:hairdule-*"
      ]
    },
    {
      "Sid": "APIGatewayAndWAFManagement",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:PATCH",
        "apigateway:DELETE",
        "wafv2:CreateWebACL",
        "wafv2:DeleteWebACL",
        "wafv2:GetWebACL",
        "wafv2:UpdateWebACL",
        "wafv2:TagResource",
        "wafv2:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3StorageAndCloudFrontManagement",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutBucketCors",
        "s3:PutEncryptionConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:PutBucketTagging",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:GetObjectTagging",
        "s3:DeleteObject",
        "s3:DeleteObjectTagging",
        "s3:ListBucket",
        "s3:AbortMultipartUpload",
        "cloudfront:CreateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:TagResource",
        "cloudfront:UntagResource",
        "cloudfront:CreateInvalidation"
      ],
      "Resource": [
        "arn:aws:s3:::hairdule-*",
        "arn:aws:s3:::hairdule-*/*",
        "arn:aws:s3:::sst-*",
        "arn:aws:s3:::sst-*/*",
        "arn:aws:cloudfront::*:distribution/*"
      ]
    },
    {
      "Sid": "EventBridgeSchedulerManagement",
      "Effect": "Allow",
      "Action": [
        "scheduler:CreateSchedule",
        "scheduler:DeleteSchedule",
        "scheduler:GetSchedule",
        "scheduler:UpdateSchedule",
        "scheduler:TagResource",
        "scheduler:UntagResource"
      ],
      "Resource": "arn:aws:scheduler:us-east-1:*:schedule/*"
    }
  ]
}
```

---

### 6. `HairdulePolicyIAMGovernance` (Governança & Proteção de IAM)
> **Finalidade:** Controlar a criação de Roles da aplicação (`hairdule-*`), limitar a transmissão de Roles (`iam:PassRole`) exclusivamente para serviços autorizados da AWS e aplicar **DENY explícito** contra qualquer tentativa de criar ou modificar usuários e chaves IAM.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAMPassRoleRestrito",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "cloudformation.amazonaws.com",
            "lambda.amazonaws.com",
            "ec2.amazonaws.com",
            "elasticloadbalancing.amazonaws.com",
            "apigateway.amazonaws.com",
            "rds.amazonaws.com",
            "cognito-idp.amazonaws.com",
            "scheduler.amazonaws.com",
            "servicediscovery.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "IAMRoleManagementRestrito",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateRole",
        "iam:UpdateAssumeRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/hairdule-*"
    },
    {
      "Sid": "IAMInstanceProfileManagement",
      "Effect": "Allow",
      "Action": [
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfiles",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagInstanceProfile",
        "iam:UntagInstanceProfile",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": "arn:aws:iam::*:instance-profile/hairdule-*"
    },
    {
      "Sid": "CloudFormationStackManagement",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:UpdateStack",
        "cloudformation:GetTemplate",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "arn:aws:cloudformation:us-east-1:*:stack/hairdule-*/*"
    },
    {
      "Sid": "DenyIAMUserAndKeyManagement",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🌟 Política Completa Consolidada Única (`HairduleFullDeploymentPolicy`)
> **Finalidade:** Para quem prefere anexar uma **única política completa** ao usuário `github-actions-staging` ou `github-actions-production` no IAM, consolidando todas as 6 camadas (SST Core, Rede, Segurança, Auth, Aurora RDS, Lambdas com `lambda:InvokeFunction` e Governança IAM).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SSTBootstrapAndState",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:PutParameter",
        "ssm:DeleteParameter",
        "ssm:DescribeParameters",
        "ssm:AddTagsToResource",
        "ssm:ListTagsForResource",
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "sts:GetCallerIdentity",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "VPCNetworkManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:ModifyVpcEndpoint",
        "ec2:RunInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeImages",
        "ec2:DescribeVolumes",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyInstanceAttribute",
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSEncryptionManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DescribeKey",
        "kms:EnableKey",
        "kms:DisableKey",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:UpdateAlias",
        "kms:ListAliases",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ListResourceTags",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsManagement",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:DeleteRetentionPolicy",
        "logs:TagResource",
        "logs:UntagResource",
        "logs:ListTagsForResource",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CognitoAuthManagement",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:CreateUserPool",
        "cognito-idp:DeleteUserPool",
        "cognito-idp:DescribeUserPool",
        "cognito-idp:UpdateUserPool",
        "cognito-idp:GetUserPoolMfaConfig",
        "cognito-idp:SetUserPoolMfaConfig",
        "cognito-idp:CreateUserPoolClient",
        "cognito-idp:DeleteUserPoolClient",
        "cognito-idp:DescribeUserPoolClient",
        "cognito-idp:UpdateUserPoolClient",
        "cognito-idp:CreateIdentityProvider",
        "cognito-idp:DeleteIdentityProvider",
        "cognito-idp:DescribeIdentityProvider",
        "cognito-idp:UpdateIdentityProvider",
        "cognito-idp:TagResource",
        "cognito-idp:UntagResource",
        "cognito-idp:ListTagsForResource"
      ],
      "Resource": "arn:aws:cognito-idp:us-east-1:*:userpool/*"
    },
    {
      "Sid": "SecretsManagerManagement",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:PutResourcePolicy",
        "secretsmanager:DeleteResourcePolicy",
        "secretsmanager:UpdateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:hairdule/*"
    },
    {
      "Sid": "AuroraPostgreSQLManagement",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:DescribeDBSubnetGroups",
        "rds:ModifyDBSubnetGroup",
        "rds:CreateDBCluster",
        "rds:DeleteDBCluster",
        "rds:DescribeDBClusters",
        "rds:DescribeGlobalClusters",
        "rds:ModifyDBCluster",
        "rds:StopDBCluster",
        "rds:StartDBCluster",
        "rds:RestoreDBClusterFromSnapshot",
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:CreateDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:ModifyDBParameterGroup",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "rds:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:rds:us-east-1:*:subgrp:hairdule-*",
        "arn:aws:rds:us-east-1:*:cluster:hairdule-*",
        "arn:aws:rds:us-east-1:*:db:*",
        "arn:aws:rds:us-east-1:*:pg:hairdule-*",
        "arn:aws:rds::*:global-cluster:*"
      ]
    },
    {
      "Sid": "RDSServiceLinkedRoleCreation",
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "rds.amazonaws.com"
        }
      }
    },
    {
      "Sid": "LambdaAndEventBridgeManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:ListVersionsByFunction",
        "lambda:ListEventSourceMappings",
        "lambda:GetFunctionCodeSigningConfig",
        "lambda:GetPolicy",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:PublishLayerVersion",
        "lambda:DeleteLayerVersion",
        "lambda:GetLayerVersion",
        "lambda:PublishVersion",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:InvokeFunction",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:ListTags",
        "events:PutRule",
        "events:DeleteRule",
        "events:DescribeRule",
        "events:ListRules",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:ListTargetsByRule",
        "events:TagResource",
        "events:UntagResource",
        "events:ListTagsForResource",
        "scheduler:CreateSchedule",
        "scheduler:DeleteSchedule",
        "scheduler:GetSchedule",
        "scheduler:UpdateSchedule",
        "scheduler:TagResource",
        "scheduler:UntagResource"
      ],
      "Resource": [
        "arn:aws:lambda:us-east-1:*:function:hairdule-*",
        "arn:aws:lambda:us-east-1:*:layer:hairdule-*",
        "arn:aws:events:us-east-1:*:rule/hairdule-*",
        "arn:aws:scheduler:us-east-1:*:schedule/*"
      ]
    },
    {
      "Sid": "APIGatewayAndWAFAndS3CDNManagement",
      "Effect": "Allow",
      "Action": [
        "apigateway:GET",
        "apigateway:POST",
        "apigateway:PUT",
        "apigateway:PATCH",
        "apigateway:DELETE",
        "wafv2:CreateWebACL",
        "wafv2:DeleteWebACL",
        "wafv2:GetWebACL",
        "wafv2:UpdateWebACL",
        "wafv2:TagResource",
        "wafv2:UntagResource",
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:PutBucketCors",
        "s3:PutEncryptionConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:PutBucketTagging",
        "cloudfront:CreateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:TagResource",
        "cloudfront:UntagResource",
        "cloudfront:CreateInvalidation"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMGovernancePassRoleAndRoles",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:UpdateRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfiles",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:TagInstanceProfile",
        "iam:UntagInstanceProfile",
        "iam:ListInstanceProfilesForRole",
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:UpdateStack",
        "cloudformation:GetTemplate",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIAMUserAndKeyManagement",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🛠️ Como Aplicar no Console da AWS

1. Vá para **AWS Console ➔ IAM ➔ Policies ➔ Create Policy**.
2. Cole o JSON da **Política Consolidada Única** acima (ou de cada uma das 6 políticas modulares) e salve como **`HairduleFullDeploymentPolicy`**.
3. Vá em **Users** (Usuários) ➔ selecione `github-actions-staging` (e `github-actions-prod`).
4. Em **Permissions**, clique em **Add permissions ➔ Attach policies directly**.
5. Selecione a política criada e confirme.
