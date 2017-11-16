#versions

PLATFORM?=$(shell uname)
PYTHON_VERSION?=2.7.9
PYWIN32_VERSION?=218
PYINSTALLER_VERSION?=3.1
SETUPTOOLS_VERSION?=0.6c11

#paths

DOWNLOAD_PATH?=.downloads
DOWNLOAD_CHECK=${DOWNLOAD_PATH}/.done
TOOLS_PATH?=.tools
TOOLS_CHECK=${TOOLS_PATH}/.done
WINE_PATH=~/.wine
DRIVEC_PATH=${WINE_PATH}/drive_c
NSIS_PATH=${DRIVEC_PATH}/NSIS

#files
PYINSTALLER_ZIP=PyInstaller-${PYINSTALLER_VERSION}.zip
PYTHON_MSI=python-${PYTHON_VERSION}.msi

#urls
PYINSTALLER_URL=https://pypi.python.org/packages/source/P/PyInstaller/${PYINSTALLER_ZIP}
PYTHON_MSI_URL=http://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_MSI}

#libs
MSVCP90=${DRIVEC_PATH}/Python27/msvcp90.dll
PYINSTALLER=${TOOLS_PATH}/PyInstaller-${PYINSTALLER_VERSION}/pyinstaller.py

WINDOWS_BINARIES=${PYWIN32_CHECK}

#executables
MAKENSIS_EXE=${NSIS_PATH}/makensis.exe
PYTHON_EXE=${DRIVEC_PATH}/Python27/python.exe
PIP_EXE=${DRIVEC_PATH}/Python27/Scripts/pip.exe


${DOWNLOAD_CHECK}:
	@echo "Creating dependencies dir: \c"
	@mkdir -p ${DOWNLOAD_PATH} && touch $@
	${CHECK}

${TOOLS_CHECK}:
	@echo "Creating tools dir: \c"
	@mkdir -p ${TOOLS_PATH} && touch $@
	${CHECK}

${DOWNLOAD_PATH}/${PYINSTALLER_ZIP}: ${DOWNLOAD_CHECK}
	@echo "Downloading ${PYINSTALLER_ZIP}: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} ${PYINSTALLER_URL} && \
		cd .. && touch $@
	${CHECK}

${DOWNLOAD_PATH}/${PYTHON_MSI}: ${DOWNLOAD_CHECK}
	@echo "Downloading ${PYTHON_MSI}: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} ${PYTHON_MSI_URL} && \
		cd .. && touch $@
	${CHECK}

${PYTHON_EXE}: ${DOWNLOAD_PATH}/${PYTHON_MSI}
	@cd ${DOWNLOAD_PATH} && \
		msiexec /i ${PYTHON_MSI} /qb
	@touch $@

${DRIVEC_PATH}/Python27/msvcp90.dll: ${DRIVEC_PATH}/windows/system32/msvcp90.dll
	@cp $< $@

${CHECKPOINT_DIR}/pypiwin32.check: ${PYTHON_EXE} ${CHECKPOINT}
	@wine ${PIP_EXE} install pypiwin32 || wine ${PYTHON_EXE} -m pip install pypiwin32
	touch $@

${PYINSTALLER}: ${TOOLS_CHECK} ${DOWNLOAD_PATH}/${PYINSTALLER_ZIP} ${CHECKPOINT_DIR}/pypiwin32.check
	@echo "Unzipping ${PYINSTALLER_ZIP}: \c"
	@cd ${TOOLS_PATH} && \
		unzip -qq ../${DOWNLOAD_PATH}/${PYINSTALLER_ZIP} && \
		cd .. && touch $@
	${CHECK}

${TOOLS_PATH}/requirements.windows.check: ${PYTHON_EXE} requirements.txt
	@echo wine ${PIP_EXE} install -r requirements.txt
	@wine ${PIP_EXE} install -r requirements.txt || wine ${PYTHON_EXE} -m pip install -r requirements.txt
	@touch $@
