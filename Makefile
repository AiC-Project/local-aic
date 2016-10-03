
clean:
	rm -f lib/images/services.tar lib/images/player.tar

#
# Install repo
#

bin/repo:
	curl https://storage.googleapis.com/git-repo-downloads/repo -o bin/repo
	chmod 755 bin/repo

#
# Load prebuilt player + service images
#

docker-load:
	docker load -i lib/images/services.tar
	docker load -i lib/images/player.tar


#
# Source donwload + sync
#

src:
	mkdir src

src/senza: | src
	mkdir src/senza

src/player: | src
	cd src; git clone git@github.com:AiC-Project/player.git

src/player.compose: | src
	cd src; git clone git@github.com:AiC-Project/player.compose.git

src/player.camera: | src
	cd src; git clone git@github.com:AiC-Project/player.camera.git

src/senza/ats.util: | src/senza
	cd src/senza; git clone git@github.com:AiC-Project/ats.util.git

src/senza/ats.client: | src/senza
	cd src/senza; git clone git@github.com:AiC-Project/ats.client.git

src/senza/ats.senza: | src/senza
	cd src/senza; git clone git@github.com:AiC-Project/ats.senza.git


#
# Build player set
#

player-build: src/player src/player.compose src/player.camera
	cd src/player; make docker-all
	cd src/player.camera; make docker-all
	cd src/player.compose; make clean docker-images

#
# Build frontend + AMQP
#

TAG ?= latest

src/senza/Dockerfile:
	ln -s ats.senza/Dockerfile src/senza/Dockerfile

services-build: src/senza/ats.util src/senza/ats.client src/senza/ats.senza src/senza/Dockerfile
	docker build -f src/senza/Dockerfile src/senza -t aic.senza:${TAG}
	TAG=$(TAG) docker-compose -f lib/docker/services/services.yml build

lib/images:
	mkdir lib/images

docker-save: services-build player-build | lib/images
	docker save -o lib/images/services.tar aic.senza
	docker save -o lib/images/player.tar aic.ffserver aic.xorg aic.prjdata aic.avmdata aic.sdl aic.camera aic.audio aic.sensors


#
# Build VM
#

src/rom: | src
	mkdir src/rom

rom-init-kitkat: | src/rom bin/repo
	cd src/rom; $(shell pwd)/bin/repo init -u git@github.com:AiC-Project/manifest.git -b aic-kitkat

#rom-init-lollipop: | src/rom bin/repo
#	cd src/rom; $(shell pwd)/bin/repo init -u git@git.rnd.alterway.fr:aic_vm/manifest.git -b aic-lollipop

rom-sync: | src/rom bin/repo
	cd src/rom; $(shell pwd)/bin/repo sync

rom-sync-force: | src/rom bin/repo
	cd src/rom; $(shell pwd)/bin/repo sync --force-sync

#rom-discard: src/rom
#	cd src/rom; repo forall -vc "git reset --hard"

# Build everything within a docker container, by sharing the source volume.
# Build dependencies are not required on the host, except for the make command and Docker.

aospwrap = docker run --rm -ti -v ${CURDIR}/lib/docker/buildaosp:/home/developer/build -v ${CURDIR}/src/rom:/home/developer/rom -v ${CURDIR}/src/.ccache:/home/developer/.ccache -ti aic.aospbuilder

docker-build-rom-builder:
	docker build --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) -t aic.aospbuilder lib/docker/buildaosp

src/.ccache:
	mkdir src/.ccache

rom-build: docker-build-rom-builder | src src/.ccache
	$(aospwrap) bash build/build gobyp
	bash ./lib/docker/buildaosp/move_built_img gobyp
	$(aospwrap) bash build/build gobyt
	bash ./lib/docker/buildaosp/move_built_img gobyt
