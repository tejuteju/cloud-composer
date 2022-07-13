endpoint                 = true
img_version              = "composer-2.0.19-airflow-2.2.5"
airflow_config_overrides = "Viewer"
cidr                     = "10.128.0.0/20"
//sa="composer-sa@spatial-ship-354209.iam.gserviceaccount.com"
//kms="projects/spatial-ship-354209/locations/us-central1/keyRings/composer-keyring-01/cryptoKeys/composer-key-01"
project = "spatial-ship-354209"
keyring = "keyring-example-03"
keyname = "crypto-key-example-01"
sa      = "composer-test-sa-01"
composer_name = "composer-02"

