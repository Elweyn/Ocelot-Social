#!/usr/bin/env bash
ROOT_DIR=$(dirname "$0")/..
# BUILD_COMMIT=${TRAVIS_COMMIT:-$(git rev-parse HEAD)}

VERSION=$(jq -r '.version' $ROOT_DIR/package.json)
IFS='.' read -r major minor patch <<< $VERSION
apps=(develop-webapp develop-backend develop-neo4j develop-maintenance)
tags=($major $major.$minor $major.$minor.$patch)

# These three docker images have already been built by now:
# docker build --build-arg BUILD_COMMIT=$BUILD_COMMIT --target production -t ocelotsocialnetwork/develop-backend:latest $ROOT_DIR/backend
# docker build --build-arg BUILD_COMMIT=$BUILD_COMMIT --target production -t ocelotsocialnetwork/develop-webapp:latest $ROOT_DIR/webapp
# docker build --build-arg BUILD_COMMIT=$BUILD_COMMIT -t ocelotsocialnetwork/develop-neo4j:latest $ROOT_DIR/neo4j
docker build -t ocelotsocialnetwork/develop-maintenance:latest $ROOT_DIR/webapp/ -f $ROOT_DIR/webapp/Dockerfile.maintenance

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

for app in "${apps[@]}"
do
  SOURCE="ocelotsocialnetwork/${app}:latest"
  echo "docker push $SOURCE"
  docker push $SOURCE

  for tag in "${tags[@]}"
  do
    TARGET="ocelotsocialnetwork/${app}:${tag}"
    if DOCKER_CLI_EXPERIMENTAL=enabled docker manifest inspect $TARGET >/dev/null; then
      echo "docker image ${TARGET} already present, skipping ..."
    else
      echo -e "docker tag $SOURCE $TARGET\ndocker push $TARGET"
      docker tag $SOURCE $TARGET
      docker push $TARGET
    fi
  done
done
