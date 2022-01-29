# syntax=docker/dockerfile:1.3-labs
FROM nyamisty/docker-wine-dotnet:win64-devel
MAINTAINER NyaMisty

ARG PYTHON_VER=3.9.6
ARG USE_IDAPYSWITCH=1
ARG IDA_LICENSE_NAME=docker-wine-ida
ARG DOCKER_PASSWORD=DockerWineIDA

SHELL ["/bin/bash", "-c"]

WORKDIR /root

# Configure profile for Wine
RUN true \
    && echo "root:$DOCKER_PASSWORD" | chpasswd

# Install Python first
RUN --security=insecure true \
    && (entrypoint true; sleep 0.5; wineboot --init) \
    && (entrypoint true; sleep 0.5; winetricks -q win10) \
    && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
    && if [[ $PYTHON_VER == 2* ]]; then \
           wget "https://www.python.org/ftp/python/${PYTHON_VER}/python-${PYTHON_VER}.amd64.msi" \
           && (wine cmd /c msiexec /i python-2.7.18.amd64.msi /qn /L*V! python_inst.log; ret=$?; cat python_inst.log; rm python_inst.log; exit $ret); \
       else \
           wget "https://www.python.org/ftp/python/${PYTHON_VER}/python-${PYTHON_VER}-amd64.exe" \
           && (wine cmd /c python*.* /quiet /log python_inst.log InstallAllUsers=1 PrependPath=1; ret=$?; cat python_inst.log; rm python_inst.log; exit $ret); \
       fi \
    && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
    && winetricks -q win7 \
    && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done \
    && rm -rf $HOME/.cache/winetricks && rm python*


# Configure IDA
ADD . /root/.wine/drive_c/IDA
RUN true \
    && if [ "$USE_IDAPYSWITCH" = "1" ]; then (echo 0 | wine 'C:\IDA\idapyswitch.exe'; wine cmd /c reg delete 'HKCU\Software\Hex-Rays\IDA' /v Python3TargetDLL /f); fi \
    && wine cmd /c reg add 'HKCU\Software\Hex-Rays\IDA' /v "License $IDA_LICENSE_NAME" /t REG_DWORD /d 1 /f \
    && while pgrep wineserver >/dev/null; do echo "Waiting for wineserver"; sleep 1; done
