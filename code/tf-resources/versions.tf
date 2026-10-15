terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Rama 6 del provider. La exige aws-apigateway@2, el unico modulo que pide
      # >= 6.0; el resto aceptan las dos ramas. No se puede subir el modulo sin
      # subir esto: quedarse en ~> 5.37 rompe el init en cuanto se resuelve la
      # ref @2.
      #
      # El != 6.69.0 no es mania: esa version rompe la subida del codigo de la
      # lambda. UpdateFunctionCode muere con "decomposing request: bufio.Scanner:
      # token too long" y no hay forma de desplegar. Lo sufrio
      # cloud-authorizer-gateway el 14 y 15 de octubre de 2026, cinco applies
      # seguidos; 6.68.0 sube codigo sin problema. Sin esta linea, cada repo que
      # nazca de la plantilla arranca con la version rota.
      #
      # Aqui no va .terraform.lock.hcl a proposito, aunque en los repos de estado
      # si: en una plantilla se quedaria rancio enseguida y el
      # serverless-state-sync-template solo copia los .tf, no lo propagaria. El
      # repo nuevo genera el suyo con "terraform init" la primera vez.
      version = "~> 6.0, != 6.69.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
