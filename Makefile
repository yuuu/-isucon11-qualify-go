.DEFAULT_GOAL := help

MYSQL_HOST="127.0.0.1"
MYSQL_PORT=3306
MYSQL_USER=isucon
MYSQL_DBNAME=isucondition
MYSQL_PASS=isucon
MYSQL=mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
SLOW_LOG=/tmp/slow-query.log
ISSUE=1
ANALYZE_FILE=/tmp/analyze.txt

restart: ## Copy configs from repository to conf
	@make -s nginx-restart
	@make -s db-restart
	@make -s db-log-on
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

db-log-on: ## Slow query on to mysql
	@sudo touch $(SLOW_LOG)
	@sudo rm $(SLOW_LOG)
	@sudo systemctl restart mysql
	@$(MYSQL) -e "set global slow_query_log_file = '$(SLOW_LOG)'; set global long_query_time = 0.001; set global slow_query_log = ON;"
	@echo 'DB log on'

db-log-off: ## Slow query off to mysql
	@$(MYSQL) -e "set global slow_query_log = OFF;"
	@echo 'DB log off'

db-log-show: ## Show slow query to mysql
	@sudo mysqldumpslow -s t $(SLOW_LOG) | head -n 20

pprof: ## Launch pprof web server
	@go tool pprof -http=0.0.0.0:8080 /home/isucon/webapp/go/isucondition http://localhost:6060/debug/pprof/profile

analyze: ## Exec alp and slow-query-log, and sent logs to github issue.
	@echo "alp\n\n\`\`\`" > $(ANALYZE_FILE)
	@make -s alp >> $(ANALYZE_FILE)
	@echo "\`\`\`\n\n" >> $(ANALYZE_FILE)
	@echo "slow-query-log\n\n\`\`\`" >> $(ANALYZE_FILE)
	@make -s db-log-show >> $(ANALYZE_FILE)
	@echo "\`\`\`\n\n" >> $(ANALYZE_FILE)
	@gh issue comment $(ISSUE) -F $(ANALYZE_FILE)


.PHONY: help
help:
	@grep -E '^[a-z0-9A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
