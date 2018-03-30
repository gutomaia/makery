VIRTUALENV_DIR?=venv
VIRTUALENV_ARGS?=
VIRTUALENV_CMD=${VIRTUALENV_DIR}/bin/activate
VIRTUALENV=@. ${VIRTUALENV_CMD};

PIP_EXTRA_PARAMS?=

PYTHON_MODULES?=${shell find}

PYTHON_SOURCES?=${shell find ${PYTHON_MODULES} -type f -iname '*.py'}
PYTHON_COMPILED?= $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})

CHECKPOINT_DIR?=.checkpoint
CHECKPOINT=${CHECKPOINT_DIR}/python_mk.check

REQUIREMENTS=${CHECKPOINT_DIR}/requirements.txt
REQUIREMENTS_TEST=${CHECKPOINT_DIR}/requirements_test.txt

python_default: python_test

${CHECKPOINT}:
	@mkdir -p ${CHECKPOINT_DIR} && touch $@

${VIRTUALENV_CMD}:
	@test -d ${VIRTUALENV_DIR} || virtualenv ${VIRTUALENV_ARGS} ${VIRTUALENV_DIR} > /dev/null && touch $@

${CHECKPOINT_DIR}/.upgrade_pip: ${CHECKPOINT} ${VIRTUALENV_CMD}
	${VIRTUALENV} pip install --upgrade pip && touch $@

${REQUIREMENTS}: ${CHECKPOINT_DIR}/.upgrade_pip requirements.txt
	${VIRTUALENV} pip install -r requirements.txt ${PIP_EXTRA_PARAMS} && \
		touch $@

${REQUIREMENTS_TEST}: ${CHECKPOINT} ${VIRTUALENV_CMD} requirements_test.txt
	${VIRTUALENV} pip install -r requirements_test.txt ${PIP_EXTRA_PARAMS} && \
		touch $@

%.pyc: %.py
	@echo "Compiling $<: \c"
	${VIRTUALENV} python -m py_compile $<
	${CHECK}

python_dependencies: ${REQUIREMENTS}

${CHECKPOINT_DIR}/wheel.check: ${CHECKPOINT_DIR}/.upgrade_pip
	${VIRTUALENV} pip install --upgrade wheel && touch $@

python_build: python_dependencies

${CHECKPOINT_DIR}/.python_develop: ${CHECKPOINT} setup.py
	${VIRTUALENV} python setup.py develop && touch $@

python_test: python_build ${REQUIREMENTS_TEST}
	${VIRTUALENV} nosetests

python_clean:
	@rm -rf ${CHECKPOINT_DIR}
	@find ${PYTHON_MODULES} -regex '^.*py[co]$$' -type f -delete
	@find ${PYTHON_MODULES} -name __pycache__ -type d -delete
	@rm -rf build
	@rm -rf *.egg-info
	@rm -rf dist
	@rm -rf reports

python_purge: python_clean
	@rm -rf deps
	@rm -rf tools
	@rm -rf ${VIRTUALENV_DIR}

python_egg: setup.py ${PYTHON_COMPILED}
	${VIRTUALENV} python setup.py bdist_egg --exclude-source-files > /dev/null

python_wheel: setup.py ${PYTHON_COMPILED} ${CHECKPOINT_DIR}/wheel.check
	${VIRTUALENV} python setup.py bdist_wheel > /dev/null
