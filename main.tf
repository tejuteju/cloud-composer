provider "google" {
  project = var.project
  region  = "us-central1"
  //access_token          = var.access_token
}
data "google_project" "project" {
}
resource "google_composer_environment" "test" {
  name   = var.composer_name
  region = "us-central1"
  config {
    //node_count = 3
    software_config {
      image_version = var.img_version
      airflow_config_overrides = {
        webserver-rbac_user_registration_role = var.airflow_config_overrides
      }
    }
    node_config {
      service_account = google_service_account.composer-sa.name
    }

    encryption_config {
      //kms_key_name = "projects/${data.google_project.project.project_id} /locations/us-central1/keyRings/${google_kms_key_ring.keyring.name}/cryptoKeys/${google_kms_crypto_key.key.name}"
      kms_key_name = google_kms_crypto_key.key.id
    }

    private_environment_config {
      enable_private_endpoint = var.endpoint

    }
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }


    }
    master_authorized_networks_config {

      enabled = true

      cidr_blocks {
        cidr_block = var.cidr
      }
    }

  }
}

resource "google_kms_key_ring" "keyring" {
  name     = var.keyring
  location = "us-central1"
}
resource "google_kms_crypto_key" "key" {
  name            = var.keyname
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_service_account" "composer-sa" {
  account_id   = var.sa
  display_name = "Test Service Account for Composer Environment"
  project      = var.project
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.composer-sa.email}"
}
resource "google_project_iam_member" "composer_sa_environments_worker" {
  project = var.project
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer-sa.email}"
}
resource "google_project_iam_member" "composer_sa_environments_admin" {
  project = var.project
  role    = "roles/composer.admin"
  member  = "serviceAccount:${google_service_account.composer-sa.email}"
}
resource "google_project_iam_member" "composer_sa_environments_sa_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.composer-sa.email}"
}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project
}
resource "google_project_service_identity" "artifactregistry_identity" {
  provider = google-beta
  project  = var.project
  service  = "artifactregistry.googleapis.com"
}

locals {
  kms_decrypter_users = [
    "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com",
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  ]
  composer_bindings = {
    "composer_service_agent" = {
      member = "serviceAccount:service-${data.google_project.project.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
      role   = "roles/composer.ServiceAgentV2Ext"
    }
  }
}
resource "google_kms_crypto_key_iam_member" "service_account_iam_crypto_key" {
  for_each      = toset(local.kms_decrypter_users)
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
  depends_on    = [google_project_service_identity.artifactregistry_identity]
}
resource "google_project_iam_member" "composer" {
  for_each = local.composer_bindings
  project  = data.google_project.project.project_id
  role     = each.value.role
  member   = each.value.member
}
