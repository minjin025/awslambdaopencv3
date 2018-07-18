#!/bin/bash

# Setting up build env
sudo yum update -y

sudo yum -y groupinstall development
wget https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tar.xz
tar xJf Python-3.6.3.tar.xz
cd Python-3.6.3
./configure
make
sudo make install

cd ..
sudo yum install -y git gcc-c++ gcc python-devel chrpath
mkdir -p lambda-package/cv2 build/numpy

# cmake
version=3.5
build=1
mkdir ~/temp
cd ~/temp

wget https://cmake.org/files/v$version/cmake-$version.$build.tar.gz
tar -xzvf cmake-$version.$build.tar.gz
cd cmake-$version.$build/
./bootstrap
make -j2
sudo make install
cd ~

# Build numpy
sudo /usr/local/bin/pip3.6 install numpy
cp -rf /usr/local/lib64/python3.6/site-packages/numpy lambda-package

alias python=python3.6
# Build OpenCV 3.2
(
	cd ~/build
	git clone https://github.com/opencv/opencv
	cd opencv
    rm CMakeCache
	git checkout 3.4
    mkdir build
    cd build
	/usr/local/bin/cmake -D CMAKE_BUILD_TYPE=RELEASE        \
        -D WITH_TBB=ON \
        -D WITH_IPP=ON \
        -D WITH_V4L=ON \
        -D ENABLE_AVX=ON \
        -D ENABLE_SSSE3=ON\
        -D ENABLE_SSE41=ON\
        -D ENABLE_SSE42=ON\
        -D ENABLE_POPCNT=ON\
        -D ENABLE_FAST_MATH=ON\
        -D BUILD_EXAMPLES=ON\
        -D BUILD_TESTS=OFF\
        -D BUILD_PERF_TESTS=OFF\
        -D BUILD_opencv_python2=OFF\
        -D BUILD_opencv_python3=ON\
        -D PYTHON_INCLUDE_DIR=/usr/include/python3.6m\
        -D PYTHON_LIBRARY=/usr/lib64/libpython3.6m.so\
        -D PYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib64/python3.6/site-packages/numpy/core/include     \
        -D PYTHON3_EXECUTABLE=/usr/bin/python3.6 ..

	make -j`cat /proc/cpuinfo | grep MHz | wc -l`
    sudo make install
)
cp ~/build/opencv/build/lib/python3/cv2.cpython-36m-x86_64-linux-gnu.so ~/lambda-package/cv2/__init__.so
cp -L ~/build/opencv/build/lib/*.so.3.4 ~/lambda-package/cv2
strip --strip-all ~/lambda-package/cv2/*
chrpath -r '$ORIGIN' ~/lambda-package/cv2/__init__.so
touch ~/lambda-package/cv2/__init__.py

# Copy template function and zip package
cp template.py lambda-package/lambda_function.py
cd lambda-package
zip -r ../lambda-package.zip *
