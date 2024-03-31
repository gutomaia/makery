OK=\033[32m[OK]\033[39m
FAIL=\033[31m[FAIL]\033[39m
CHECK=@if [ $$? -eq 0 ]; then echo "${OK}"; else echo "${FAIL}" ; fi

PROJECT_NAME?=Project
PROJECT_TAG?=project

CHECKPOINT_DIR?=.checkpoint
REQUIREMENTS_TEST?=${CHECKPOINT_DIR}/requirements_test.txt
VERSION_FILE?=${PYTHON_MODULES}/__init__.py
CURRENT_VERSION?=$(shell poetry version | cut -d' ' -f 2)
CHANGELOG_FILE?=CHANGELOG.md
CHANGELOG_DOC?=docs/changelog.rst
GIT_TAG_EXTRA_ARGS?=
DEFAULT_VERSION_BEHAVIOR=test
REQUIREMENTS_LICENCES=docs/requirements_licenses.rst
REQUIREMENTS_DEV_LICENSES=docs/requirements_dev_licenses.rst

major: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump major version file (${VERSION_FILE}): \c"
	${VIRTUALENV} poetry version major
	${CHECK}
	@make create-tag

minor: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump minor version file (${VERSION_FILE}): \c"
	${VIRTUALENV} poetry version minor
	${CHECK}
	@make create-tag

patch: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump patch version file (${VERSION_FILE}): \c"
	${VIRTUALENV} poetry version patch
	${CHECK}
	@make create-tag

create-tag: ${REQUIREMENTS_LICENCES} ${REQUIREMENTS_DEV_LICENSES}
	@echo "Added version file (${VERSION_FILE}) to repository: \c"
	@git add ${VERSION_FILE}
	@git add pyproject.toml
	@git add ${REQUIREMENTS_LICENCES}
	@git add ${REQUIREMENTS_DEV_LICENSES}
	${CHECK}

	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] echo "Commit version v"[]" to repository: \c"
	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] git commit -m "New ${PROJECT_NAME} version []" -q
	${CHECK}

	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] echo "Temporary tag version v"[]" to repository: \c"
	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] git tag -a v[] -m '${PROJECT_NAME} version []' ${GIT_TAG_EXTRA_ARGS}
	${CHECK}

	@echo "Create changelog file (${CHANGELOG_FILE}): \c"
	${VIRTUALENV} git-changelog -c angular . -o ${CHANGELOG_FILE}
	${CHECK}

	@echo "Create changelog doc file (${CHANGELOG_DOC}): \c"
	${VIRTUALENV} m2r ${CHANGELOG_FILE} && mv CHANGELOG.rst ${CHANGELOG_DOC}
	${CHECK}

	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] echo "Remove temporary tag version v"[]" from repository: \c"
	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] git tag -d v[]
	${CHECK}

	@echo "Added changelog file (${CHANGELOG_FILE}) to repository: \c"
	@git add ${CHANGELOG_FILE}
	${CHECK}

	@test -d docs || mkdir -p docs

	@echo "Added changelog doc file (${CHANGELOG_DOC}) to repository: \c"
	@git add ${CHANGELOG_DOC}
	${CHECK}

	@echo "Amend commit with changelog: \c"
	@git commit --amend --no-edit
	${CHECK}

	@echo "Create changelog file (${VERSION_FILE}): \c"
	${VIRTUALENV} poetry version | cut -d' ' -f 2 | xargs -I [] git tag -a v[] -m '${PROJECT_NAME} version []' ${GIT_TAG_EXTRA_ARGS}
	${CHECK}

	@echo "Push branch to repository: \c"
	@git branch | grep \* | cut -d' ' -f 2 | xargs git push origin
	${CHECK}

	@echo "Push tags to repository: \c"
	@python setup.py --version | xargs -I [] git push origin v[]
	${CHECK}
