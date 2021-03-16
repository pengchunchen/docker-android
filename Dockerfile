FROM openjdk:8-jdk
MAINTAINER pengchunchen 

ARG ITFARM_REPO
ARG SSHKEY
ARG ITFARM_PKGS
ARG ITFARM_PORT
ARG ITFARM_HOST
ARG ITFARM_HOSTNAME

RUN dpkg --add-architecture i386 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install -yq libc6:i386 libstdc++6:i386 zlib1g:i386 libncurses5:i386 libqt5widgets5 build-essential libssl-dev lib32z1 --no-install-recommends && \
    apt-get -y install vim && \
     apt-get -y install yum && \
    apt-get clean


# Download and unzip Android SDK tools with SDK manager (here used 26.1.0, https://dl.google.com/android/repository/repository2-1.xml)
RUN mkdir -p /usr/local/android-sdk-linux
RUN wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
     unzip -qq -o android-sdk.zip -d /usr/local/android-sdk-linux
RUN rm android-sdk.zip

# Set environment variable
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools:$PATH
ENV PATH=$PATH:/opt/gradle/gradle-5.4.1/bin
ENV ANDROID_TARGET_SDK="29" \
    ANDROID_BUILD_TOOLS="29.0.3" \
    ANDROID_COMPILE_SDK="29" \
    ANDROID_PLATFORM_TOOLS="29"

# Update and install using sdkmanager
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}"
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "platform-tools" "platforms;android-${ANDROID_PLATFORM_TOOLS}"
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}"
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "extras;google;google_play_services"
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "extras;google;m2repository"
RUN echo y | $ANDROID_HOME/tools/bin/sdkmanager "extras;android;m2repository"

#RUN rm android-emulator.zip
#ADD android-wait-for-emulator.sh $ANDROID_HOME/ci/
#ADD stop-emulators.sh $ANDROID_HOME/ci/

#download gradle
RUN wget --quiet --output-document=gradle-5.4.1-bin.zip https://services.gradle.org/distributions/gradle-5.4.1-bin.zip
RUN mkdir /opt/gradle
RUN unzip -d /opt/gradle gradle-5.4.1-bin.zip
RUN rm gradle-5.4.1-bin.zip

# Make ssh dir
RUN mkdir /root/.ssh/

# Copy over private key, and set permissions
#COPY id_rsa /root/.ssh/id_rsa
RUN echo "$SSHKEY" >> /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
#RUN chown -R root:root /root/.ssh

# Create known_hosts
#RUN touch /root/.ssh/known_hosts
# Remove host checking
RUN echo "Host $ITFARM_HOST\nHostName $ITFARM_HOSTNAME\nPort $ITFARM_PORT\nUser git\nIdentityFile /root/.ssh/id_rsa\nStrictHostKeyChecking no\n" >> /root/.ssh/config

# setup git account
RUN git config --global user.email "itfarmuser@corp-ci.com"
RUN git config --global user.name "itfarmuser"

# Clone the conf files into the docker container
RUN git clone $ITFARM_REPO /home/android
#RUN sed -i '/com.github.bumptech.glide:glide:4.12.0/d' /home/android/app/build.gradle
#RUN sed -i "/dependencies {/a implementation 'com.github.bumptech.glide:glide:4.12.0'" /home/android/app/build.gradle
COPY android.sh /home/android/app/android.sh
RUN chmod +x /home/android/app/android.sh
RUN cd /home/android/app && \
    bash android.sh $ITFARM_PKGS build.gradle && \
    rm -f android.sh

RUN cd /home/android && \
    git add -A && \
	git commit -m "docker test" && \
	git push origin master

