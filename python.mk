PYTHON_VERSION?=3.10
PYTHON_CMD?=python${PYTHON_VERSION}
VIRTUALENV_DIR?=venv
VIRTUALENV_ARGS?=-p ${PYTHON_CMD}
VIRTUALENV_ACTIVATE=${VIRTUALENV_DIR}/bin/activate
VIRTUALENV=@. ${VIRTUALENV_ACTIVATE};

PIP_EXTRA_PARAMS?=

PYTHON_MODULES?=${shell find}

PYTHON_SOURCES?=${shell find ${PYTHON_MODULES} -type f -iname '*.py'}
PYTHON_COMPILED?= $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})

CHECKPOINT_DIR?=.checkpoint
CHECKPOINT=${CHECKPOINT_DIR}/python_mk.check

ifeq "true" "${shell test -f pyproject.toml && echo true}"
REQUIREMENTS=${CHECKPOINT_DIR}/pyproject.toml
REQUIREMENTS_TEST=${CHECKPOINT_DIR}/pyproject_test.toml
else
REQUIREMENTS=${CHECKPOINT_DIR}/requirements.txt
REQUIREMENTS_TEST=${CHECKPOINT_DIR}/requirements_test.txt
endif

python_default: python_test

${CHECKPOINT}:
	@mkdir -p ${CHECKPOINT_DIR} && touch $@

${VIRTUALENV_ACTIVATE}:
	@test -d ${VIRTUALENV_DIR} || virtualenv ${VIRTUALENV_ARGS} ${VIRTUALENV_DIR} > /dev/null && touch $@

${CHECKPOINT_DIR}/.pip_tools: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE}
	${VIRTUALENV} pip install pip-tools && touch $@

${CHECKPOINT_DIR}/.upgrade_pip: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE}
	${VIRTUALENV} pip install pip --upgrade && touch $@

requirements.txt: ${CHECKPOINT_DIR}/.upgrade_pip ${CHECKPOINT_DIR}/.pip_tools requirements.in
	${VIRTUALENV} pip-compile requirements.in ${PIP_EXTRA_PARAMS} --no-emit-index-url --no-header

requirements_test.txt: ${CHECKPOINT_DIR}/.upgrade_pip ${CHECKPOINT_DIR}/.pip_tools requirements_test.in
	${VIRTUALENV} pip-compile requirements_test.in ${PIP_EXTRA_PARAMS} --no-emit-index-url --no-header

${CHECKPOINT_DIR}/.poetry: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE} ${CHECKPOINT_DIR}/.upgrade_pip
	${VIRTUALENV} pip install poetry && touch $@

${CHECKPOINT_DIR}/.python_develop: ${CHECKPOINT} setup.py
	${VIRTUALENV} python setup.py develop && touch $@

ifeq "true" "${shell test -f pyproject.toml && echo true}"
${REQUIREMENTS}: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE} ${CHECKPOINT_DIR}/.poetry pyproject.toml
	${VIRTUALENV} poetry install && touch $@

${REQUIREMENTS_TEST}: ${REQUIREMENTS}

python_dependencies: ${REQUIREMENTS}

else
${REQUIREMENTS}: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE} requirements.txt requirements_test.txt
	${VIRTUALENV} pip install -r requirements.txt ${PIP_EXTRA_PARAMS} && \
		touch $@

${REQUIREMENTS_TEST}: ${CHECKPOINT} ${VIRTUALENV_ACTIVATE} requirements_test.txt
	${VIRTUALENV} pip install -r requirements_test.txt ${PIP_EXTRA_PARAMS} && \
		touch $@

python_dependencies: ${REQUIREMENTS} ${CHECKPOINT_DIR}/.python_develop
endif

%.pyc: %.py
	@echo "Compiling $<: \c"
	${VIRTUALENV} python -m py_compile $<
	${CHECK}

${CHECKPOINT_DIR}/wheel.check: ${CHECKPOINT_DIR}/.upgrade_pip
	${VIRTUALENV} pip install --upgrade wheel && touch $@

ifeq "" "$(shell which ${PYTHON_CMD})"
python_build:
	@echo "Please install Python ${PYTHON_VERSION}"
	@echo "Visit https://www.python.org/downloads/ to Download it? [y/N] " && read ans && [ $${ans:-N} = y ]
	@open https://www.python.org/downloads/
	exit 1
else
python_build: python_dependencies
endif

python_clean:
	@rm -rf ${CHECKPOINT_DIR}
	@find ${PYTHON_MODULES} -regex '^.*py[co]$$' -type f -delete
	@find ${PYTHON_MODULES} -name __pycache__ -type d | xargs rm -rf
	@rm -rf build
	@rm -rf *.egg-info
	@rm -rf dist
	@rm -rf reports
	@rm -rf .pytest_cache
	@rm -rf __pycache__

python_purge: python_clean
	@rm -rf deps
	@rm -rf tools
	@rm -rf ${VIRTUALENV_DIR}

ifeq "true" "${shell test -f pyproject.toml && echo true}"

python_egg: pyproject.toml ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/.poetry
	${VIRTUALENV} poetry build -f sdist

python_wheel: pyproject.toml ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/.poetry
	${VIRTUALENV} poetry build -f wheel

python_spec_wheel: setup_spec.py ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/wheel.check
	${VIRTUALENV} python setup_spec.py bdist_wheel

else
python_egg: setup.py ${PYTHON_COMPILED}
	${VIRTUALENV} python setup.py bdist_egg --exclude-source-files > /dev/null

python_wheel: setup.py ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/wheel.check
	${VIRTUALENV} python setup.py bdist_wheel

python_spec_wheel: setup_spec.py ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/wheel.check
	${VIRTUALENV} python setup_spec.py bdist_wheel
endif

