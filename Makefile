.DEFAULT_GOAL := help

restart: ## Copy configs from repository to conf
	@make -s nginx-restart
	@make -s db-restart
	@make -s go-restart

go-log: ## Log Server
	@sudo journalctl -f -u isucondition.go.service

go-restart: ## Restart Server
	@sudo systemctl daemon-reload
	@cd go && go build
	@sudo systemctl restart isucondition.go.service
	@echo 'Restart go app'

nginx-restart: ## Restart nginx
	@sudo cp -a nginx/* /etc/nginx/
	@sudo rm /var/log/nginx/access.log
	@sudo rm /var/log/nginx/error.log
	@sudo systemctl restart nginx
	@echo 'Restart nginx'

nginx-access-log: ## Tail nginx access.log
	@sudo tail -f /var/log/nginx/access.log

nginx-error-log: ## Tail nginx error.log
	@sudo tail -f /var/log/nginx/error.log

alp: ## Run alp
	@sudo cat /var/log/nginx/access.log | alp ltsv -m '/api/condition/[a-z0-9-]+, /api/isu/[a-z0-9-]+/icon, /api/isu/[a-z0-9-]+/graph, /api/isu/[a-z0-9-]+, /isu/[a-z0-9-]+, /assets/[a-z0-9-]+'

db-restart: ## Restart mysql
	@sudo cp -a mysql/* /etc/mysql/
	@sudo systemctl restart mysql
	@echo 'Restart mysql'

myprofiler: ## Run myprofiler
	@myprofiler -user=isucon -password=isucon

.PHONY: help
help:
	@grep -E '^[a-z0-9A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
