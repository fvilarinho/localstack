all: install dist check

clean:
	@chmod +x stop.sh
	@./stop.sh

install:
	@chmod +x install.sh
	@./install.sh
	@./start.sh

dist:
	@chmod +x deploy.sh
	@./deploy.sh

check:
	@chmod +x validate.sh
	@./validate.sh