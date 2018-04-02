# certbot-pipeline

Certbot (Let's Encrypt) pipeline script

# Installation

This utilizes [pyenv](https://github.com/pyenv/pyenv) in order to create a virtual environment to work out of. After configuration, just run `./certbot.sh install` and an environment with certbot installed will be created. If you do not want to use a virtual environment, run the same command with `USE_VENV=false`.

Currently, the virtual environment installation only targets Debian.

# Configuration

In order to generate a certificate, the following values must be provided:

| Name  | Description  |
|---|---|
| CERTBOT_HOSTED_ZONE | Hosted zone (root domain) to generate certificates for |
| CERTBOT_DOMAIN | Domain to generate a certificate for |
| CERTBOT_EMAIL | Email to use for certificate generation |

Additionally, if using the [Certbot Hurricane Electric Hook](https://github.com/adammillerio/certbot-he-hook), there are three additional configuration values:

| Name  | Default  | Description  |
|---|---|---|
| HE_USERNAME | (none) | Username for Hurricane Electric |
| HE_PASSWORD | (none) | Password for Hurricane Electric |
| HE_ZONE | $CERTBOT_HOSTED_ZONE | Hosted zone (root domain) in HE to create the validation record under |

The following additional environment variables are available for advanced configuration:

| Name  | Default  | Description  |
|---|---|---|
| PYTHON_VERSION | 3.6.5 | Version of Python to be installed in the virtual environment |
| CERTBOT_VERSION | 0.22.2 | Version of certbot to be installed |
| BS4_VERISON | 4.6.0 | If using the HE hook, the BeautifulSoup4 version to install |
| USE_HE_HOOK | true | Whether or not the [Certbot Hurricane Electric Hook](https://github.com/adammillerio/certbot-he-hook) is to be used |
| USE_VENV | true | Whether or not a Python virtual environment is to be used |
| CERTBOT_SERVER | ACME V2 URL | URL for the ACME server to use, switch to staging for testing |
| CERTBOT_LOGS_DIR | ./domains/$CERTBOT_HOSTED_ZONE/logs | Directory to store certbot logs in |
| CERTBOT_CONFIG_DIR | ./domains/$CERTBOT_HOSTED_ZONE/config | Directory to store certbot configuration and certificates in |
| CERTBOT_WORK_DIR | ./domains/$CERTBOT_HOSTED_ZONE/work | Working directory for certbot |

# Usage

The pipeline script provides two functions, the first is `./certbot.sh generate`, which will generate a new certificate. The scond is `./certbot.sh renew`, which renews all certificates for a hosted zone.

When running either action, the script will check whether or not there is a `./domains/$CERTBOT_HOSTED_ZONE` folder for the current hosted zone. This allows for the configuration to be separated out between domains.