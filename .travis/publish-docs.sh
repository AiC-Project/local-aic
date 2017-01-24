#!/bin/bash
set -e

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K "$ENCRYPTED_KEY" -iv "$ENCRYPTED_IV" -in .travis/deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval "$(ssh-agent -s)"
ssh-add deploy_key

# Push build to repository
ssh-add -l
git config --global user.email "Travis Docs CI"
git config --global user.name "Travis Docs CI"
git clone "$GIT_PUB_REPO" "$GIT_PUB_LOCAL_DIR" -b "$GIT_PUB_BRANCH"

# remove old version
cd "$GIT_PUB_LOCAL_DIR"
git rm -r "$GIT_PUB_SUB_DIR"
cd ..

# add new version
mv "$GIT_PUB_BUILD_DIR" "${GIT_PUB_LOCAL_DIR:?}/${GIT_PUB_SUB_DIR:?}"

# publish
cd "$GIT_PUB_LOCAL_DIR"
git add "$GIT_PUB_SUB_DIR"

# nothing to commit?
git diff --staged --quiet && exit 0

git commit -m "Updating docs."
git push "$GIT_PUB_REPO" "$GIT_PUB_BRANCH"
