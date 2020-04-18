SHELL     := /bin/bash
AWK       ?= gawk                                 # old macOS awk won't work
JQ        ?= jq                                   # CLI JSON parser
CLIPBOARD ?= xclip -sel clip                      # command to copy to clipboard

# REPO_URL  := $(shell git config --get remote.origin.url)
# REPO_NAME := $(shell ${AWK} -F'com/' '{print $$2}' <<< ${REPO_URL})
PACKAGES ?= package.json

NPM_REGISTY   =  registry.npmjs.org
NPM_LOG_LEVEL =  error

# Note: workflows don't seem to run locally
# CircleCI seems like it has a higher ceiling, but travis is much simpler
CIRCLECI      ?= circleci
TRAVIS        ?= travis
CIRCLE_CONFIG =  ${CURDIR}/.circleci/config.yml
TRAVIS_CONFIG =  ${CURDIR}/.travis.yml
CI_JOB        ?= build

.PHONY: all package.json
all: help ## No default targets -- just print this message
	@

README.md: README.org
	pandoc -s $^ -o $@

package.json:   ## merge package.json with base-packages.json
	${JQ} -s '.[0] * .[1]' base-packages.json ${PACKAGES} > $@


#~~~~~~~~ Npm Registy ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.PHONY: npm-token
npm-token: ## Copy current npmjs registry authToken to clipboard
	@( set -eo pipefail; yarn config list --json | tail -n1 |          \
	${JQ} -r ".data[\"//${NPM_REGISTY}/:_authToken\"]" |               \
	${CLIPBOARD} && echo "Copied authToken to clipboard" ) 2>/dev/null \
	|| { echo "Failed to copy authToken" && true; } # don't fail either way

npm-login: npm-token ## Login to brmlia npmjs registry
	@npm login --scope @brmlia


#~~~~~~~~ CircleCI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.PHONY: browse-ci check-ci run-ci dump-ci check-tv
browse-ci: ## Check circleci builds online
	@${BROWSER} https://circleci.com/gh/${REPO_NAME}

check-ci: ## Validates circleci configuration file locally
	@${CIRCLECI} config validate ${CIRCLE_CONFIG}

run-ci: ## Run circleci locally -- requires docker/circleci setup
	${CIRCLECI} local execute --job ${CI_JOB}

dump-ci: ## Dump the result of processing circleci setup to stdout
	@${CIRCLECI} config process ${CIRCLE_CONFIG}

#~~~~~~~~ Travis ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

check-tv: ## validate .travis.yml (requires 'gem install travis')
	@${TRAVIS} lint ${TRAVIS_CONFIG}

push: check-tv check-ci ## validate CI config's prior to pushing commits
	$(info Iriie)
	git push -u


clean: ## Remove build/test/deploy directories
	$(RM) -r coverage *~ build dist

.PHONY: clean-all
clean-all: clean ## Remove all caches + lock files
	$(RM) -r node_modules package-lock.json yarn.lock .pnp/ .pnp.js

.PHONY: help
help:  ## Display this help message
	@for mfile in $(MAKEFILE_LIST); do                  \
	  grep -E '^[a-zA-Z_%-]+:.*?## .*$$' $$mfile |      \
	  sort | ${AWK}                                     \
	  'BEGIN {FS = ":.*?## "};                          \
	   {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'; \
	done
