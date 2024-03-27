OK=\033[32m[OK]\033[39m
FAIL=\033[31m[FAIL]\033[39m
CHECK=@if [ $$? -eq 0 ]; then echo "${OK}"; else echo "${FAIL}" ; fi

PROJECT_NAME?=Project
PROJECT_TAG?=project

CHECKPOINT_DIR?=.checkpoint
REQUIREMENTS_TEST?=${CHECKPOINT_DIR}/requirements_test.txt
VERSION_FILE?=${PYTHON_MODULES}/__init__.py
CURRENT_VERSION?=$(shell python setup.py --version)
CHANGELOG_FILE?=CHANGELOG.md
CHANGELOG_DOC?=docs/changelog.rst
GIT_TAG_EXTRA_ARGS?=
DEFAULT_VERSION_BEHAVIOR=test

major: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump major version file (${VERSION_FILE}): \c"
	${VIRTUALENV} bumpversion --current-version ${CURRENT_VERSION} major ${VERSION_FILE}
	${CHECK}
	@make create-tag

minor: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump minor version file (${VERSION_FILE}): \c"
	${VIRTUALENV} bumpversion --current-version ${CURRENT_VERSION} minor ${VERSION_FILE}
	${CHECK}
	@make create-tag

patch: ${DEFAULT_VERSION_BEHAVIOR} ${REQUIREMENTS_TEST}
	@echo "Bump patch version file (${VERSION_FILE}): \c"
	${VIRTUALENV} bumpversion --current-version ${CURRENT_VERSION} patch ${VERSION_FILE}
	${CHECK}
	@make create-tag

create-tag:
	@echo "Added version file (${VERSION_FILE}) to repository: \c"
	@git add ${VERSION_FILE}
	${CHECK}

	@python setup.py --version | xargs -I [] echo "Commit version v"[]" to repository: \c"
	@python setup.py --version | xargs -I [] git commit -m "New ${PROJECT_NAME} version []" -q
	${CHECK}

	@python setup.py --version | xargs -I [] echo "Temporary tag version v"[]" to repository: \c"
	@python setup.py --version | xargs -I [] git tag -a v[] -m '${PROJECT_NAME} version []' ${GIT_TAG_EXTRA_ARGS}
	${CHECK}

	@echo "Create changelog file (${CHANGELOG_FILE}): \c"
	${VIRTUALENV} git-changelog -s angular . -o ${CHANGELOG_FILE}
	${CHECK}

	@echo "Create changelog doc file (${CHANGELOG_DOC}): \c"
	${VIRTUALENV} m2r ${CHANGELOG_FILE} && mv CHANGELOG.rst ${CHANGELOG_DOC}
	${CHECK}

	@python setup.py --version | xargs -I [] echo "Remove temporary tag version v"[]" from repository: \c"
	@python setup.py --version | xargs -I [] git tag -d v[]
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
	@python setup.py --version | xargs -I [] git tag -a v[] -m '${PROJECT_NAME} version []' ${GIT_TAG_EXTRA_ARGS}
	${CHECK}

	@echo "Push branch to repository: \c"
	@git branch | grep \* | cut -d' ' -f 2 | xargs git push origin
	${CHECK}

	@echo "Push tags to repository: \c"
	@python setup.py --version | xargs -I [] git push origin v[]
	${CHECK}
