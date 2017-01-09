
clean:
	rm -f lib/images/services.tar lib/images/player.tar

#
# Load prebuilt player + service images
#

.PHONY: docker-load
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

.PHONY: player-build
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

.PHONY: services-build
services-build: src/senza/ats.util src/senza/ats.client src/senza/ats.senza src/senza/Dockerfile
	docker build -f src/senza/Dockerfile src/senza -t aic.senza:${TAG}
	TAG=$(TAG) docker-compose -f lib/docker/services/services.yml build

lib/images:
	mkdir lib/images

.PHONY: docker-save
docker-save: services-build player-build | lib/images
	docker save -o lib/images/services.tar aic.senza
	docker save -o lib/images/player.tar aic.ffserver aic.xorg aic.prjdata aic.avmdata aic.sdl aic.camera aic.audio aic.sensors aic.adb

