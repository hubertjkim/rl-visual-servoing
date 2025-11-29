# =========================================================
# Container B: ROS 2 Humble + Isaac ROS + CUDA + TensorRT
# Base image from NVIDIA NGC (includes: CUDA, TensorRT, VPI)
# =========================================================
FROM nvcr.io/nvidia/isaac/ros:x86_64-ros2_humble_f247dd1051869171c3fc53bb35f6b907

# Switch to root to perform installations (NVIDIA images sometimes default to 'admin')
USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# ---------------------------------------------------------
# Basic utilities
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git wget curl nano cmake build-essential \
    python3 python3-pip python3-colcon-common-extensions \
    libgl1-mesa-glx libglib2.0-0 x11-apps \
    && apt-get clean

RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install "setuptools<70" "setuptools-scm<8"

# =========================================================
# xArm ROS 2 Workspace
# =========================================================
WORKDIR /app/xarm_ros2_ws
RUN mkdir -p src

RUN git clone https://github.com/xArm-Developer/xarm_ros2.git \
    --recursive -b $ROS_DISTRO src/xarm_ros2 && \
    cd src/xarm_ros2 && \
    git submodule update --init --recursive && \
    git pull --recurse-submodules

RUN apt-get update && rosdep update && \
    rosdep install --from-paths src --ignore-src --rosdistro $ROS_DISTRO -y

# =========================================================
# RealSense Camera + RealSense ROS 2 Wrapper
# =========================================================
RUN mkdir -p /etc/apt/keyrings && \
    curl -sSf https://librealsense.intel.com/Debian/librealsense.pgp \
    | tee /etc/apt/keyrings/librealsense.pgp > /dev/null

RUN echo "deb [signed-by=/etc/apt/keyrings/librealsense.pgp] \
    https://librealsense.intel.com/Debian/apt-repo `lsb_release -cs` main" \
    | tee /etc/apt/sources.list.d/librealsense.list

RUN apt-get update && apt-get install -y \
    librealsense2-utils librealsense2-dev librealsense2-dbg \
    ros-humble-realsense2-camera ros-humble-diagnostic-updater \
    && apt-get clean

# =========================================================
# Isaac ROS Workspace (Optional but Recommended)
# =========================================================
WORKDIR /app/isaac_ros_ws
RUN mkdir -p src

# Example: clone Isaac ROS Common (others optional)
RUN git clone https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git src/isaac_ros_common

# Install dependencies for Isaac ROS packages
RUN apt-get update && rosdep update && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro $ROS_DISTRO

# =========================================================
# Environment setup
# =========================================================
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc
RUN echo "source /app/xarm_ros2_ws/install/setup.bash" >> /root/.bashrc
RUN echo "source /app/isaac_ros_ws/install/setup.bash" >> /root/.bashrc

# =========================================================
# Keep container alive
# =========================================================
CMD ["tail", "-f", "/dev/null"]
