all: install start dist check

clean:
	rm -rf temp
	rm iac/*.*state
	rm output.log
install:
	@chmod +x install.sh
	@./install.sh

start:
	@chmod +x start.sh
	@./start.sh

stop:
	@chmod +x stop.sh
	@./stop.sh

dist:
	@chmod +x deploy.sh
	@./deploy.sh

check:
	@chmod +x validate.sh
	@./validate.sh