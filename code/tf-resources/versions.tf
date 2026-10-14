terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Rama 6 del provider. La exige aws-apigateway@2, el unico modulo que pide
      # >= 6.0; el resto aceptan las dos ramas. No se puede subir el modulo sin
      # subir esto: quedarse en ~> 5.37 rompe el init en cuanto se resuelve la
      # ref @2.
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
