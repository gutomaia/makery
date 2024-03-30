WGET?=wget -q
GH_WGET?=${WGET} --header "Authorization: token ${GITHUB_TOKEN}"

ifeq "" "$(shell which wget)"
WGET?=curl -O -s -L -s
GH_WGET?=${WGET} -H "Authorization: token ${GITHUB_TOKEN}"
endif

PYTHON_VERSION?=3.11
MAKEFILE_SCRIPT_PATH?=extras/makefiles
OK?=\033[32m[OK]\033[39m
FAIL?=\033[31m[FAIL]\033[39m
CHECK?=@if [ $$? -eq 0 ]; then echo "${OK}"; else echo "${FAIL}" ; fi
PLANTUML_VERSION?=1.2022.6
PLANTUML_JAR?=plantuml-${PLANTUML_VERSION}.jar
MAKERY_REPOSITORY?=gutomaia/gutonet-makery
MAKERY_REPOSITORY_BRANCH?=main
MAKERY_BASE_URL?=https://raw.githubusercontent.com/${MAKERY_REPOSITORY}/${MAKERY_REPOSITORY_BRANCH}
DEFAULT_BEHAVIOR?=test code_check
CHANGELOG_FILE?=CHANGELOG.md
CHANGELOG_DOC?=docs/changelog.rst

FLAKE8_IGNORE?=W503,E203
FLAKE8_ARGS?=--ignore=${FLAKE8_IGNORE} --per-file-ignores=\*/__init__.py\:F401,F403

ifeq "true" "${shell test -d docs && echo true}"
DOCS_RST?=${shell find docs -type f -iname '*.rst'} docs/requirements_licenses.rst docs/requirements_dev_licenses.rst ${CHANGELOG_DOC}
else
DOCS_RST?=
endif

default_makery: ${MAKEFILE_SCRIPT_PATH}/python.mk ${MAKEFILE_SCRIPT_PATH}/github.mk
	@$(MAKE) -C . ${DEFAULT_BEHAVIOR}

ifeq "true" "${shell test -f ${MAKEFILE_SCRIPT_PATH}/python.mk && echo true}"
include ${MAKEFILE_SCRIPT_PATH}/python.mk
endif

ifeq "true" "${shell test -f ${MAKEFILE_SCRIPT_PATH}/github.mk && echo true}"
include ${MAKEFILE_SCRIPT_PATH}/github.mk
endif

help:
	@echo "to be fullfileed"

${MAKEFILE_SCRIPT_PATH}/python.mk:
	@echo "Download python.mk at extras/makefiles: \c"
	@mkdir -p ${MAKEFILE_SCRIPT_PATH} && \
		cd ${MAKEFILE_SCRIPT_PATH} && \
		${GH_WGET} ${MAKERY_BASE_URL}/python.mk && \
		touch python.mk
	${CHECK}

${MAKEFILE_SCRIPT_PATH}/github.mk:
	@echo "Download github.mk at extras/makefiles: \c"
	@mkdir -p ${MAKEFILE_SCRIPT_PATH} && \
		cd ${MAKEFILE_SCRIPT_PATH} && \
		${GH_WGET} ${MAKERY_BASE_URL}/github.mk && \
		touch github.mk
	${CHECK}

clean: python_clean
	@rm -rf docs/_build

purge: python_purge
	@rm -rf docs/plantuml.jar
	@rm -rf ${MAKEFILE_SCRIPT_PATH}

build: python_build

test: build ${REQUIREMENTS_TEST}
	${VIRTUALENV} py.test ${PYTHON_MODULES} --ignore ${PYTHON_MODULES}/tests/integration

codestyle_check: ${REQUIREMENTS_TEST}
	${VIRTUALENV} pycodestyle ${PYTHON_MODULES} | sort -rn || echo ''

flake_check: ${REQUIREMENTS_TEST}
	${VIRTUALENV} flake8 ${PYTHON_MODULES} ${FLAKE8_ARGS}

blue_check: ${REQUIREMENTS_TEST}
	${VIRTUALENV} blue --check ${PYTHON_MODULES}

bandit_check:
	${VIRTUALENV} bandit -r $(PYTHON_MODULES)

ipdb_check:
	@find ${PYTHON_MODULES} -regex .*\.py$ | xargs -I [] egrep -H -n 'print|ipdb' [] || echo ''

code_check: blue_check codestyle_check flake_check bandit_check ipdb_check

fix_style: ${REQUIREMENTS_TEST}
	${VIRTUALENV} blue ${PYTHON_MODULES}

pdb: build ${REQUIREMENTS_TEST}
	${VIRTUALENV} CI=1 py.test ${PYTHON_MODULES} -x --ff --pdb --ignore ${PYTHON_MODULES}/tests/integration

ci:
ifeq "true" "${TRAVIS}"
	CI=1 py.test ${PYTHON_MODULES} --durations=10 --cov=${PYTHON_MODULES} ${PYTHON_MODULES}/tests/ --cov-config .coveragerc --cov-report=xml --junitxml=pytest-report.xml
else
	${VIRTUALENV} CI=1 py.test ${PYTHON_MODULES} --durations=10 --cov=${PYTHON_MODULES} ${PYTHON_MODULES}/tests/ --cov-config .coveragerc --cov-report=xml --junitxml=pytest-report.xml
endif

coverage: build ${REQUIREMENTS_TEST}
	${VIRTUALENV} CI=1 py.test ${PYTHON_MODULES} --cov=${PYTHON_MODULES} ${PYTHON_MODULES}/tests/ --cov-config .coveragerc --cov-report term-missing --cov-report html:cov_html --cov-report xml:cov.xml --cov-report annotate:cov_annotate

todo: ${REQUIREMENTS_TEST}
	${VIRTUALENV} flake8 ${PYTHON_MODULES}
	${VIRTUALENV} pycodestyle --first ${PYTHON_MODULES}
	find ${PYTHON_MODULES} -type f | xargs -I [] grep -H TODO []

search:
	find ${PYTHON_MODULES} -regex .*\.py$ | xargs -I [] egrep -H -n 'print|ipdb' [] || echo ''

report:
	coverage run --source=${PYTHON_MODULES} setup.py test

tdd: ${REQUIREMENTS_TEST}
	${VIRTUALENV} ptw --ignore ${VIRTUALENV_DIR} --ignore ${PYTHON_MODULES}/tests/integration/

tox: ${REQUIREMENTS_TEST}
	${VIRTUALENV} tox

${CHANGELOG_FILE}:
	@echo "Create changelog file (${CHANGELOG_FILE}): \c"
	${VIRTUALENV} git-changelog -c angular . -o ${CHANGELOG_FILE}
	${CHECK}

${CHANGELOG_DOC}: ${CHANGELOG_FILE} ${REQUIREMENTS_TEST}
	@echo "Create changelog doc (${CHANGELOG_DOC}): \c"
	${VIRTUALENV} m2r ${CHANGELOG_FILE}
	@mv CHANGELOG.rst $@
	${CHECK}

docs/requirements_licenses.rst: pyproject.toml
	@echo "Create requirements_venv at docs/_build: \c"
	@mkdir -p docs/_build && cd docs/_build && virtualenv requirements_venv ${VIRTUALENV_ARGS}
	${CHECK}
	@echo "Upgrade pip at requirements_venv: \c"
	@. docs/_build/requirements_venv/bin/activate; pip3 install pip --upgrade --quiet
	${CHECK}
	@echo "Upgrade poetry at requirements_venv: \c"
	@. docs/_build/requirements_venv/bin/activate; pip3 install poetry --quiet
	${CHECK}
	@echo "Install requirements.txt at requirements_venv: \c"
	@. docs/_build/requirements_venv/bin/activate; poetry install --only-root
	${CHECK}
	@echo "Install pip-licenses at requirements_venv: \c"
	@. docs/_build/requirements_venv/bin/activate; pip3 install pip-licenses --quiet
	${CHECK}
	@echo "Generate $@ with pip-licenses: \c"
	@. docs/_build/requirements_venv/bin/activate; pip-licenses --format rst --output-file $@
	${CHECK}

docs/requirements_dev_licenses.rst: pyproject.toml
	@echo "Create requirements_dev_venv at docs/_build: \c"
	@mkdir -p docs/_build && cd docs/_build && virtualenv requirements_dev_venv ${VIRTUALENV_ARGS}
	${CHECK}
	@echo "Upgrade pip at requirements_dev_venv: \c"
	@. docs/_build/requirements_dev_venv/bin/activate; pip3 install pip --upgrade --quiet
	${CHECK}
	@echo "Upgrade poetry at requirements_dev_venv: \c"
	@. docs/_build/requirements_dev_venv/bin/activate; pip3 install poetry --quiet
	${CHECK}
	@echo "Install requirements.txt at requirements_dev_venv: \c"
	@. docs/_build/requirements_dev_venv/bin/activate; poetry install --only=dev --no-root
	${CHECK}
	@echo "Install pip-licenses at requirements_dev_venv: \c"
	@. docs/_build/requirements_dev_venv/bin/activate; pip3 install pip-licenses --quiet
	${CHECK}
	@echo "Generate $@ with pip-licenses: \c"
	@. docs/_build/requirements_dev_venv/bin/activate; pip-licenses --format rst --output-file $@
	${CHECK}

docs/${PLANTUML_JAR}:
	@echo "Download ${PLANTUML_ZIP} at docs: \c"
	@cd docs && ${WGET} https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/${PLANTUML_JAR}
	${CHECK}

docs/plantuml.jar: docs/${PLANTUML_JAR}
	@echo "Unzip plantuml.jar from ${PLANTUML_ZIP} at docs: \c"
	@cd docs && cp ${PLANTUML_JAR} plantuml.jar
	${CHECK}

docs: ${REQUIREMENTS_TEST} docs/${PLANTUML_JAR} ${DOCS_RST}
	@${VIRTUALENV} $(MAKE) -C docs html

docs/_build/latex/${PROJECT_TAG}.tex: ${REQUIREMENTS_TEST} ${PYTHON_SOURCES} ${DOCS_RST} docs/plantuml.jar
	rm -rf docs/_build/latex
	${VIRTUALENV} $(MAKE) -C docs latex

pdf: docs/_build/latex/${PROJECT_TAG}.tex
	$(MAKE) -C docs/_build/latex

docs_ci: docs/plantuml.jar
	${MAKE} -C docs html

ifeq "true" "${shell test -f setup_spec.py && echo true}"
dist: python_wheel python_spec_wheel
else
dist: python_wheel
endif


deploy_twine: ${REQUIREMENTS_TEST} dist
ifeq "true" "${TRAVIS}"
	twine upload dist/*.whl
else
	${VIRTUALENV} twine upload dist/*.whl
endif


.PHONY: clean purge build dist docs deploy deploy_s3 deploy_twine
