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
TOOLS_CHECK=${TOOLS_PATH}

#files
PYINSTALLER_ZIP=Pyinstaller-${PYINSTALLER_VERSION}.zip
PYTHON_MSI=python-${PYTHON_VERSION}.msi

#libs
MSVCP90=${WINE_PATH}/Python27/msvcp90.dll
PYINSTALLER=tools/pyinstaller-${PYINSTALLER_VERSION}/pyinstaller.py
PYWIN32=pywin32-${PYWIN32_VERSION}.win32-py2.7.exe

WINE_PATH=~/.wine/drive_c
NSIS_PATH=${WINE_PATH}/NSIS
MAKENSIS_EXE=${NSIS_PATH}/makensis.exe

PYTHON_EXE=${WINE_PATH}/Python27/python.exe
EASYINSTALL_EXE=${WINE_PATH}/Python27/Scripts/easy_install.exe
PIP_EXE=${WINE_PATH}/Python27/Scripts/pip.exe


${DOWNLOAD_CHECK}:
	@echo "Creating dependencies dir: \c"
	@mkdir -p ${DOWNLOAD_PATH}
	@touch $@
	${CHECK}

${TOOLS_CHECK}:
	@echo "Creating tools dir: \c"
	@mkdir -p tools
	@touch $@
	${CHECK}

${DOWNLOAD_PATH}/${PYINSTALLER_ZIP}: ${DOWNLOAD_CHECK}
	@echo "Downloading ${PYINSTALLER_ZIP}: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} http://sourceforge.net/projects/pyinstaller/files/${PYINSTALLER_VERSION}/pyinstaller-${PYINSTALLER_VERSION}.zip && \
		cd .. && touch $@
	${CHECK}

${DOWNLOAD_PATH}/${PYTHON_MSI}: ${DOWNLOAD_CHECK}
	@echo "Downloading ${PYTHON_MSI}: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} http://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}.msi && \
		cd .. && touch $@
	${CHECK}

${DOWNLOAD_PATH}/${PYWIN32}: ${DOWNLOAD_CHECK}
	@echo "Downloading python-${PYTHON_VERSION}.msi: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} http://downloads.sourceforge.net/project/pywin32/pywin32/Build\%20${PYWIN32_VERSION}/${PYWIN32} && \
		touch ${PYWIN32}
	${CHECK}

${PYTHON_EXE}: ${DOWNLOAD_PATH}/${PYTHON_MSI}
	@cd ${DOWNLOAD_PATH} && \
		msiexec /i ${PYTHON_MSI} /qb
	@touch $@

${WINE_PATH}/Python27/msvcp90.dll: ${WINE_PATH}/windows/system32/msvcp90.dll
	@cp $< $@

${WINE_PATH}/Python27/Scripts/pywin32_postinstall.py: ${PYTHON_EXE} ${DOWNLOAD_PATH}/${PYWIN32}
	@cd ${DOWNLOAD_PATH} && \
		echo wine ${DOWNLOAD_PATH}/${PYWIN32}
	@touch $@

${DOWNLOAD_PATH}/distribute_setup.py:
	@echo "Downloading distribute_setup.py: \c"
	@cd ${DOWNLOAD_PATH} && \
		${WGET} http://python-distribute.org/distribute_setup.py && \
		cd .. && touch $@
	${CHECK}

${EASYINSTALL_EXE}: ${PYTHON_EXE} ${DOWNLOAD_PATH}/distribute_setup.py
	cd ${DOWNLOAD_PATH} && \
		wine ${PYTHON_EXE} distribute_setup.py
	@touch $@

${PIP_EXE}: ${EASYINSTALL_EXE}
	wine ${EASYINSTALL_EXE} pip
	@touch $@

${PYINSTALLER}: ${TOOLS_CHECK} ${DOWNLOAD_PATH}/${PYINSTALLER_ZIP}
	@echo "Unzipping PyInstaller ${PYINSTALLER_VERSION}: \c"
	@cd tools && \
		unzip -qq ../${DOWNLOAD_PATH}/${PYINSTALLER_ZIP} && \
		cd .. && touch $@
	${CHECK}

tools/requirements.windows.check: ${PIP_EXE} requirements.txt
	wine ${PIP_EXE} install -r requirements.txt
	@touch $@

dependencies_wine: ${PYTHON_EXE} ${PIP_EXE}

windows_binary_dependencies: ${WINE_PATH}/Python27/Scripts/pywin32_postinstall.py

dist/linux/pynes: build ${PYINSTALLER} tools/requirements.windows.check
	@rm -rf build/pyi.linux
	@rm -rf build/pyi.linux2
	@rm -rf dist/linux
	python ${PYINSTALLER} pynes.linux.spec
	@touch $@

dist/windows/pynes.exe: ${PYINSTALLER} ${PYTHON_EXE} windows_binary_dependencies tools/requirements.windows.check
	@rm -rf build/pyi.win32
	@rm -rf dist/windows
	wine ${PYTHON_EXE} ${PYINSTALLER} --onefile pynes.windows.spec
	@touch $@

pyinstaller_linux: dist/linux/pynes

pyinstaller_windows: dist/windows/pynes.exe

dist: linux windows

deps/nsis-3.0a1-setup.exe:
	@echo "Downloading NSIS \c"
	@cd deps && \
		${WGET} http://downloads.sourceforge.net/project/nsis/NSIS%203%20Pre-release/3.0a1/nsis-3.0a1-setup.exe
	@touch "$@"
	${CHECK}

${MAKENSIS_EXE}: deps/nsis-3.0a1-setup.exe
	@echo "Installing NSIS \c"
	@wine deps/nsis-3.0a1-setup.exe /S /D=C:\\NSIS
	@touch "$@"
	${CHECK}

nsis: ${MAKENSIS_EXE} pyinstaller_windows
	@wine ${MAKENSIS_EXE} installer.nsi

pyinstaller_wizzard: nsis
