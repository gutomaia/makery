VIRTUALENV_DIR?=venv
VIRTUALENV_ARGS?=
VIRTUALENV_CMD=${VIRTUALENV_DIR/bin/activate}
VIRTUALENV=@. ${VIRTUALENV_CMD};

PYTHON_MODULES?=${shell find}

PYTHON_SOURCES?=${shell find ${PYTHON_MODULES} -type f -iname '*.py'}
PYTHON_COMPILED?= $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})

CHECKPOINT_DIR?=.checkpoint
CHECKPOINT=${CHECKPOINT_DIR}/python.check

REQUIREMENTS=${CHECKPOINT_DIR}/requirements.txt
REQUIREMENTS_TEST=${CHECKPOINT_DIR}/requirements_test.txt

python_default: python_test

${CHECKPOINT}:
	@mkdir .checkpoint && touch $@

${VIRTUALENV_CMD}:
	@test -d ${VIRTUALENV_DIR} || virtualenv ${VIRTUALENV_ARGS} ${VIRTUALENV_DIR} > /dev/null && touch $@

${REQUIREMENTS}: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements.txt
	${VIRTUALENV} pip install -r requirements.txt && \
		touch $@

${REQUIREMENTS_TEST}: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements_test.txt
	${VIRTUALENV} pip install -r requirements_test.txt && \
		touch $@

%.pyc: %.py
	@echo "Compiling $<: \c"
	${VIRTUALENV} python -m py_compile $<
	${CHECK}

python_dependencies: ${REQUIREMENTS}

python_build: python_dependencies

python_test: python_build ${REQUIREMENTS_TEST}
	${VIRTUALENV} nosetests

python_clean:
	@rm -rf ${CHECKPOINT_DIR}
	@find ${PYTHON_MODULES} -regex '^.*py[co]$$' -type f -delete
	@rm -rf build
	@rm -rf dist
	@rm -rf reports

python_purge: python_clean
	@rm -rf deps
	@rm -rf tools
	@rm -rf ${VIRTUALENV_DIR}

python_egg: setup.py ${PYTHON_COMPILED}
	${VIRTUALENV} python setup.py bdist_egg --exclude-source-files > /dev/null

python_wheel: setup.py ${PYTHON_COMPILED} ${REQUIREMENTS_TEST}
	${VIRTUALENV} python setup.py bdist_wheel > /dev/null
