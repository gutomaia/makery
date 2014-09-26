VIRTUALENV_DIR?=venv
VIRTUALENV=@. ${VIRTUALENV_DIR}/bin/activate;

PYTHON_MODULES?=${shell find}

PYTHON_SOURCES?=${shell find ${PYTHON_MODULES} -type f -iname '*.py'}
PYTHON_COMPILED?= $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})


CHECKPOINT=.checkpoint/python.check

REQUIREMENTS=.checkpoint/requirements.txt
REQUIREMENTS_TEST=.checkpoint/requirements_test.txt

python_default: python_test

${CHECKPOINT}:
	@mkdir .checkpoint && touch $@

${VIRTUALENV_DIR}/bin/activate:
	@test -d ${VIRTUALENV_DIR} || virtualenv ${VIRTUALENV_DIR} > /dev/null && touch $@

${REQUIREMENTS}: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements.txt
	${VIRTUALENV} pip install -r requirements.txt && \
		touch $@

${REQUIREMENTS_TXT}: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements_test.txt
	${VIRTUALENV} pip install -r requirements_test.txt && \
		touch $@

%.pyc: %.py
	@echo "Compiling $<: \c"
	${VIRTUALENV} python -m py_compile $<
	${CHECK}

python_dependencies: ${REQUIREMENTS}

python_build: python_dependencies

python_test: python_build ${REQUIREMENTS_TXT}
	${VIRTUALENV} nosetests

python_clean:
	@rm -rf .checkpoint
	@find ${PYTHON_MODULES} -regex '^.*py[co]$$' -type f -delete
	@rm -rf build
	@rm -rf dist
	@rm -rf reports

python_purge: python_clean
	@rm -rf deps
	@rm -rf tools
	@rm -rf ${VIRTUALENV_DIR}
