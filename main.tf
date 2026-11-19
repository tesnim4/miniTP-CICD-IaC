terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "web" {
  name = "mini-tp-cicd:1.0"
  build {
    context = "${path.module}/app"
  }
}

resource "docker_container" "web" {
  name  = "mini-tp-cicd-web"
  image = docker_image.web.image_id

  ports {
    internal = 80
    external = 8081
  }
}
