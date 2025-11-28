# ------------------------------
# Base image: Isaac Sim 5.1.0
# ------------------------------
FROM nvcr.io/nvidia/isaac-sim:5.1.0

# Switch to root to install packages
USER root

# Accept NVIDIA EULA and set non-interactive installs
ENV ACCEPT_EULA=Y \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    ROS_DISTRO=humble \
    ROS_WS=/workspace/ros2_ws

# ------------------------------
# Install dependencies: ROS2, RealSense, build tools
# ------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl gnupg2 lsb-release \
        python3-pip python3-venv \
        python3-colcon-common-extensions \
        python3-rosdep \
        ros-humble-desktop \
        ros-humble-realsense2-camera \
        vim git wget sudo \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true && rosdep update || true

# ------------------------------
# Create ROS 2 workspace
# ------------------------------
RUN mkdir -p $ROS_WS/src
WORKDIR $ROS_WS

# Optional: clone Isaac ROS common package for future expansion
RUN git clone https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git src/isaac_ros_common

# Install ROS dependencies and build workspace
RUN /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash && \
    rosdep install --from-paths src --ignore-src -r -y && \
    colcon build --symlink-install"

# Switch back to Isaac Sim user
USER developer
WORKDIR $ROS_WS

# ------------------------------
# Entry point: bash with ROS 2 environment sourced
# ------------------------------
ENTRYPOINT ["/bin/bash", "-c", "source /opt/ros/$ROS_DISTRO/setup.bash && source $ROS_WS/install/setup.bash && bash"]
