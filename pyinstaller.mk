#versions

PLATFORM?=$(shell uname)
PYTHON_VERSION?=2.7.3
PYWIN32_VERSION?=218
PYINSTALLER_VERSION?=2.1
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
PYWIN32=pywin32-${PYWIN32_VERSION}.win32-py2.7.exe

#urls
PYINSTALLER_URL=https://pypi.python.org/packages/source/P/PyInstaller/${PYINSTALLER_ZIP}
PYTHON_MSI_URL=http://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_MSI}
PYWIN32_URL=http://downloads.sourceforge.net/project/pywin32/pywin32/Build\%20${PYWIN32_VERSION}/${PYWIN32}
DISTRIBUTE_URL=https://bitbucket.org/tarek/distribute/raw/ac7d9b14ac43fecb8b65de548b25773553facaee/distribute_setup.py

#libs
MSVCP90=${DRIVEC_PATH}/Python27/msvcp90.dll
PYINSTALLER=${TOOLS_PATH}/PyInstaller-${PYINSTALLER_VERSION}/pyinstaller.py

#checks
PYWIN32_CHECK=${DRIVEC_PATH}/Python27/Scripts/pywin32_postinstall.py

WINDOWS_BINARIES=${PYWIN32_CHECK}

#executables
MAKENSIS_EXE=${NSIS_PATH}/makensis.exe
PYTHON_EXE=${DRIVEC_PATH}/Python27/python.exe
EASYINSTALL_EXE=${DRIVEC_PATH}/Python27/Scripts/easy_install.exe
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

${DOWNLOAD_PATH}/${PYWIN32}: ${DOWNLOAD_CHECK}
	@echo "Downloading python-${PYTHON_VERSION}.msi: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} ${PYWIN32_URL} && \
		touch ${PYWIN32}
	${CHECK}

${PYTHON_EXE}: ${DOWNLOAD_PATH}/${PYTHON_MSI}
	@cd ${DOWNLOAD_PATH} && \
		msiexec /i ${PYTHON_MSI} /qb
	@touch $@

${DRIVEC_PATH}/Python27/msvcp90.dll: ${DRIVEC_PATH}/windows/system32/msvcp90.dll
	@cp $< $@

${EASYINSTALL_EXE}: ${PYTHON_EXE} ${DOWNLOAD_PATH}/distribute_setup.py
	@cd ${DOWNLOAD_PATH} && \
		wine ${PYTHON_EXE} distribute_setup.py
	@touch $@

${PYWIN32_CHECK}: ${EASYINSTALL_EXE} ${DOWNLOAD_PATH}/${PYWIN32}
	@wine ${EASYINSTALL_EXE} ${DOWNLOAD_PATH}/${PYWIN32} && touch $@

${DOWNLOAD_PATH}/distribute_setup.py:
	@echo "Downloading distribute_setup.py: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} ${DISTRIBUTE_URL} && \
		cd .. && touch $@
	${CHECK}

${PIP_EXE}: ${EASYINSTALL_EXE}
	@test -f ${PIP_EXE} || wine ${EASYINSTALL_EXE} pip
	@touch $@

${PYINSTALLER}: ${TOOLS_CHECK} ${DOWNLOAD_PATH}/${PYINSTALLER_ZIP}
	@echo "Unzipping ${PYINSTALLER_ZIP}: \c"
	@cd ${TOOLS_PATH} && \
		unzip -qq ../${DOWNLOAD_PATH}/${PYINSTALLER_ZIP} && \
		cd .. && touch $@
	${CHECK}

${TOOLS_PATH}/requirements.windows.check: ${PIP_EXE} requirements.txt
	@echo wine ${PIP_EXE} install -r requirements.txt
	@wine ${PIP_EXE} install -r requirements.txt || wine ${PYTHON_EXE} -m pip install -r requirements.txt
	@touch $@

dist/linux/pynes: build ${PYINSTALLER}
	@rm -rf build/pyi.linux
	@rm -rf build/pyi.linux2
	@rm -rf dist/linux
	python ${PYINSTALLER} pynes.linux.spec
	@touch $@

dist/windows/pynes.exe: ${PYINSTALLER} ${PYTHON_EXE} ${WINDOWS_BINARIES} ${TOOLS_PATH}/requirements.windows.check
	@rm -rf build/pyi.win32
	@rm -rf dist/windows
	wine ${PYTHON_EXE} ${PYINSTALLER} --onefile pynes.windows.spec
	@touch $@

pyinstaller_linux: dist/linux/pynes

pyinstaller_windows: dist/windows/pynes.exe

${DOWNLOAD_PATH}/nsis-3.0a1-setup.exe:
	@echo "Downloading NSIS \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} http://downloads.sourceforge.net/project/nsis/NSIS%203%20Pre-release/3.0a1/nsis-3.0a1-setup.exe
	@touch "$@"
	${CHECK}

${MAKENSIS_EXE}: ${DOWNLOAD_PATH}/nsis-3.0a1-setup.exe
	@echo "Installing NSIS: \c"
	@wine ${DOWNLOAD_PATH}/nsis-3.0a1-setup.exe /S /D=C:\\NSIS
	@touch "$@"
	${CHECK}

nsis: ${MAKENSIS_EXE}
	@wine ${MAKENSIS_EXE} installer.nsi

pyinstaller_wizzard: nsis
