.PHONY: build
build:
	@docker build -t dcss .
.PHONY: deploy
deploy: build
	@heroku container:login
	@heroku container:push web
	@heroku container:release web
	@heroku logs --tail	
.PHONY: run
run:
	@docker run --privileged -p 8080:8080 -it dcss /bin/bash