VIRTUALENV_DIR?=venv
VIRTUALENV=@. ${VIRTUALENV_DIR}/bin/activate;

PYTHON_MODULE?=${shell find}

PYTHON_SOURCES?=${}
PYTHON_COMPILED?= $(patsubst %.py,%.pyc, ${PYTHON_SOURCES})

CHECKPOINT=.checkpoint/python.check

VIRTUALENV=@. ${VIRTUALENV_DIR}/bin/activate;



${CHECKPOINT}:
	@mkdir .checkpoint && touch $@

${VIRTUALENV_DIR}/bin/activate:
	@test -d ${VIRTUALENV_DIR} || virtualenv ${VIRTUALENV_DIR} > /dev/null && touch $@

.checkpoint/requirements.txt: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements.txt
	${VIRTUALENV} pip install -r requirements.txt && \
		touch $@

.checkpoint/requirements_test.txt: ${CHECKPOINT} ${VIRTUALENV_DIR}/bin/activate requirements_test.txt
	${VIRTUALENV} pip install -r requirements_test.txt && \
		touch $@

%.pyc: %.py
	@echo "Compiling $<: \c"
	${VIRTUALENV} python -m py_compile $<
	${CHECK}

python_dependencies: .checkpoint/requirements.txt

python_build: python_dependencies

python_test: python_build .checkpoint/requirements_test.txt
	${VIRTUALENV} nosetests

