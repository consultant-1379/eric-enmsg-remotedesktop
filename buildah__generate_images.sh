#!/bin/bash
export ISO_VERSION=0.0.0


current_folder_name=$(basename "$PWD")
image_name=eric-enmsg-remotedesktop
build_context=.

echo ${build_context} ${image_name}
export image_path=armdocker.rnd.ericsson.se/proj_oss_releases/${image_name}

git tag | grep "$(cat VERSION_PREFIX)-" &> /dev/null

if [ $? -gt 0 ]; then
  export image_version="$(cat VERSION_PREFIX)-1"
else
  export image_version=$(git tag | grep "$(cat VERSION_PREFIX)-" | sort --version-sort --field-separator=- --key=2,2 | tail -n1)-aurora
fi

rm -rf image_id
rm -rf $PWD/tmp
mkdir -p $PWD/zypper_cache
mkdir -p $PWD/tmp/var/log


time buildah bud --iidfile=image_id --layers --pull \
--build-arg KEEP_DOWNLOADED_RPMS=true \
-v $PWD/zypper_cache:/var/cache/zypp \
-v $PWD/tmp/var/log:/var/log \
-v $PWD/image_content/:/image_content \
-v $PWD/build/:/build \
-f ${build_context}/Dockerfile -t "$image_path:$image_version" ${build_context}

STATUS=$?

if [ $STATUS -eq 0 ]; then
   echo "Pushing image to remote registry."
   IMAGE_ID=$(cat image_id)
   time buildah push $IMAGE_ID "docker://$image_path:$image_version"
   buildah images | grep ${IMAGE_ID}
fi



