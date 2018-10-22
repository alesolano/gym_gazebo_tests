from osrf/ros:kinetic-desktop-full

# Thanks to http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/

RUN apt-get update && \
      apt-get -y install sudo

#-------------------------------#

# Create user (replace 1000 with your user / group id (which is usually 1000))
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

# Needed to use the screen (we'll be able to run gedit or firefox, or visualize images with no problem)
#ENV DISPLAY

# Upgrade OpenGL/MESA 3D graphics, needed to visualize Rviz and Gazebo (from: http://ubuntuhandbook.org/index.php/2018/01/how-to-install-mesa-17-3-3-in-ubuntu-16-04-17-10/)
RUN apt-get -y install software-properties-common && \
    add-apt-repository ppa:ubuntu-x-swat/updates && \
    apt-get update && apt-get -y dist-upgrade

# Needed for visualizing Gazebo
ENV QT_X11_NO_MITSHM=1

#-------------------------------#

# Install ros-control
RUN apt-get -y install ros-kinetic-ros-control ros-kinetic-ros-controllers ros-kinetic-gazebo-ros-control

# Install gym, tensorflow, keras
RUN apt-get update && apt-get -y install python-pip
RUN pip install gym tensorflow keras

# Copy the .bashrc to the new user
RUN cp /root/.bashrc /home/developer
RUN echo "source /opt/ros/kinetic/setup.bash" >> /home/developer/.bashrc

# Set up ROS workspace
RUN mkdir -p /home/developer/catkin_ws/src
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; catkin_init_workspace /home/developer/catkin_ws/src'

# Get gym-gazebo
RUN cd /home/developer && git clone https://github.com/erlerobot/gym-gazebo
RUN cd /home/developer/gym-gazebo && pip install -e .

# Get Cartpole model
RUN cd /home/developer/catkin_ws/src && git clone https://github.com/erlerobot/cartpole_gazebo

# Change gazebo-8 to gazebo-7 in cartpole launchers
RUN sed -i 's/gazebo-8/gazebo-7/g' /home/developer/catkin_ws/src/cartpole_gazebo/launch/cartpole_gazebo.launch
RUN sed -i 's/gazebo-8/gazebo-7/g' /home/developer/gym-gazebo/gym_gazebo/envs/assets/launch/GazeboCartPole_v0.launch

# Make Cartpole model
RUN /bin/bash -c '. /opt/ros/kinetic/setup.bash; cd /home/developer/catkin_ws; catkin_make'
RUN echo "source ~/catkin_ws/devel/setup.bash" >> /home/developer/.bashrc

#-------------------------------#

USER developer
ENV HOME /home/developer

