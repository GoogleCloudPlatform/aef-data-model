terraform {
  backend "gcs" {
    bucket = "aef-annie-l-advisory-project-tfe"
    prefix = "sample-data/environments/dev"
  }
}