data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Descubrimiento de la red cuando la pipeline no la dicta.
#
# Vive aqui y no en el workflow a proposito. El primer intento lo resolvia con
# la AWS CLI en platform-ops y fallaba siempre: la imagen del runner no trae el
# binario (ghcr.io/actions/actions-runner con jq, yq, python3, node y docker, y
# nada mas), asi que salia "aws: command not found" y el paso lo interpretaba
# como "no hay red". Aqui no hace falta CLI ninguna: lo resuelve el provider,
# que ademas ya viene con el rol y la region correctos del entorno que se este
# desplegando.
#
# Solo se consultan si la pipeline no ha pasado valores, asi que en un
# despliegue normal -donde config.json los trae- estos data no se evaluan y no
# cambia nada.
data "aws_subnets" "privadas" {
  count = try(length(var.pipelinevpcsubnetids), 0) > 0 || try(length(var.vpc_subnet_ids), 0) > 0 ? 0 : 1

  filter {
    name   = "tag:Name"
    values = ["common-${local.tags.environment}-private-*"]
  }
}

data "aws_security_groups" "privado" {
  count = try(length(var.pipelinevpcsecuritygroupids), 0) > 0 || try(length(var.vpc_security_group_ids), 0) > 0 ? 0 : 1

  filter {
    name   = "group-name"
    values = ["common-${local.tags.environment}-private-sg-*"]
  }
}
