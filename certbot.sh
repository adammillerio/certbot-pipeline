#!/bin/bash
PLATFORM=$(lsb_release -i -s)
PYTHON_VERSION=${PYTHON_VERSION:-3.6.5}
CERTBOT_VERSION=${CERTBOT_VERSION:-0.22.2}
BS4_VERSION=${BS4_VERSION:-4.6.0}
USE_HE_HOOK=${USE_HE_HOOK:-true}
USE_VENV=${USE_VENV-true}

activate_venv() {
	echo 'Adding pyenv to PATH'
	PATH="~/.pyenv/bin:$PATH"

	echo 'Activating pyenv'
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"

	echo 'Activating certbot venv'
	pyenv activate certbot
}

install() {
	if [[ $USE_VENV == 'true' ]]; then
		echo 'Installing certbot virtual environment'
		deploy_venv
	fi
	
	echo 'Installing certbot'
	deploy_certbot
}

deploy_venv() {
	echo 'Installing platform specific tools'
	if [[ $PLATFORM == 'Debian' ]]; then
		sudo apt-get install --no-install-recommends -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
		libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
		xz-utils tk-dev
	fi

	echo 'Checking if pyenv is installed'
	PATH="~/.pyenv/bin:$PATH"
	which pyenv
	if [ $? == '1' ]; then
		echo 'Pyenv not found, installing'

		echo 'Installing pyenv'
		git clone https://github.com/pyenv/pyenv-installer.git pyenv-installer
		chmod +x ./pyenv-installer/pyenv-installer
		./pyenv-installer/pyenv-installer
		rm -rf ./pyenv-installer
	fi

	echo 'Activating pyenv'
	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"

	echo "Installing Python v$PYTHON_VERSION"
	pyenv install -s -v $PYTHON_VERSION

	echo 'Creating certbot virtualenv'
	pyenv virtualenv $PYTHON_VERSION certbot

	echo 'virtualenv created'
}

deploy_certbot() {
	echo 'Cloning certbot from git'
	git clone -b v$CERTBOT_VERSION https://github.com/certbot/certbot.git certbot

	echo 'Installing certbot'
	cd certbot
	python3 setup.py install
	cd ..
	rm -rf ./certbot

	if [[ $USE_HE_HOOK == 'true' ]]; then
		echo 'Installing HE hook for certbot'
		git clone https://github.com/adammillerio/certbot-he-hook.git certbot-he-hook
		pip3 install beautifulsoup4==$BS4_VERSION
	fi
}

parse_certbot() {
	CERTBOT_SERVER=${CERTBOT_SERVER:-https://acme-v02.api.letsencrypt.org/directory}
	CERTBOT_HOSTED_ZONE=${CERTBOT_HOSTED_ZONE:?'ERROR: Specify the hosted zone (root domain) with CERTBOT_HOSTED_ZONE'}
	CERTBOT_DOMAIN=${CERTBOT_DOMAIN:?'ERROR: Specify the domain to generate a cert for with CERTBOT_DOMAIN'}
	CERTBOT_EMAIL=${CERTBOT_EMAIL:?'ERROR: Specify the email to use for generation with CERTBOT_EMAIL'}
	CERTBOT_LOGS_DIR=${CERTBOT_LOGS_DIR:-./domains/$CERTBOT_HOSTED_ZONE/logs}
	CERTBOT_CONFIG_DIR=${CERTBOT_CONFIG_DIR:-./domains/$CERTBOT_HOSTED_ZONE/config}
	CERTBOT_WORK_DIR=${CERTBOT_WORK_DIR:-./domains/$CERTBOT_HOSTED_ZONE/work}

	if [[ $USE_HE_HOOK == 'true' ]]; then
		HE_USERNAME=${HE_USERNAME:?'ERROR: Specify your Hurricane Electric username as HE_USERNAME'}
		HE_PASSWORD=${HE_PASSWORD:?'ERROR: Specify your Hurricane Electric password as HE_PASSWORD'}
		export HE_ZONE=$CERTBOT_HOSTED_ZONE
	fi
}

generate() {
	echo 'Parsing certbot environment variables'
	parse_certbot

	if [ ! -d "./domains/$CERTBOT_HOSTED_ZONE" ]; then
		echo "Creating working directory for hosted zone $CERTBOT_HOSTED_ZONE"
		mkdir -pv "./domains/$CERTBOT_HOSTED_ZONE"
	fi

	echo "Generating certificate for $CERTBOT_DOMAIN"
	if [[ $USE_HE_HOOK == 'true' ]]; then
		certbot certonly \
			-n \
			--agree-tos \
			--logs-dir="$CERTBOT_LOGS_DIR" \
			--config-dir="$CERTBOT_CONFIG_DIR" \
			--work-dir="$CERTBOT_WORK_DIR" \
			--domain="$CERTBOT_DOMAIN" \
			--email="$CERTBOT_EMAIL" \
			--preferred-challenges=dns \
			--manual \
			--manual-auth-hook='python3 ./certbot-he-hook/certbot-he-hook.py' \
			--manual-cleanup-hook='python3 ./certbot-he-hook/certbot-he-hook.py' \
			--manual-public-ip-logging-ok \
			--server="$CERTBOT_SERVER"
		RESULT=$?
	else
		certbot certonly \
			-n \
			--agree-tos \
			--logs-dir="$CERTBOT_LOGS_DIR" \
			--config-dir="$CERTBOT_CONFIG_DIR" \
			--work-dir="$CERTBOT_WORK_DIR" \
			--domain="$CERTBOT_DOMAIN" \
			--email="$CERTBOT_EMAIL" \
			--preferred-challenges=dns \
			--manual-public-ip-logging-ok \
			--server="$CERTBOT_SERVER"
		RESULT=$?
	fi
	
	if [ $RESULT == '0' ]; then
		echo "Certificate generation complete for $CERTBOT_DOMAIN"
		exit 0
	else
		>&2 echo "ERROR: Certificate generation failed for $CERTBOT_DOMAIN"
		exit $RESULT
	fi
}

renew() {
	echo 'Parsing certbot environment variables'
	parse_certbot

	echo 'Renewing certificates'
	if [[ $USE_HE_HOOK == 'true' ]]; then
		certbot renew \
			-n \
			--agree-tos \
			--logs-dir="$CERTBOT_LOGS_DIR" \
			--config-dir="$CERTBOT_CONFIG_DIR" \
			--work-dir="$CERTBOT_WORK_DIR" \
			--preferred-challenges=dns \
			--manual-auth-hook='python3 ./certbot-he-hook/certbot-he-hook.py' \
			--manual-cleanup-hook='python3 ./certbot-he-hook/certbot-he-hook.py' \
			--manual-public-ip-logging-ok \
			--server="$CERTBOT_SERVER"
		RESULT=$?
	else
		certbot renew \
			-n \
			--agree-tos \
			--logs-dir="$CERTBOT_LOGS_DIR" \
			--config-dir="$CERTBOT_CONFIG_DIR" \
			--work-dir="$CERTBOT_WORK_DIR" \
			--preferred-challenges=dns \
			--manual-public-ip-logging-ok \
			--server="$CERTBOT_SERVER"
		RESULT=$?
	fi

	if [ $RESULT == '0' ]; then
		echo 'Certificate renewal complete'
		exit 0
	else
		>&2 echo 'ERROR: Certificate renewal failed'
		exit $RESULT
	fi
}

if [[ $USE_VENV == 'true' && $1 != 'deploy_venv' && $1 != 'install' ]]; then
	echo 'Activating certbot virtual environment'
	activate_venv
fi

$1
