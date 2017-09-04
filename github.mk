
PROJECT_NAME?=Project
PROJECT_TAG?=project

VERSION.txt:
	echo '0.0.0' > VERSION.txt

before-tag:
	@rm -f /tmp/.${PROJECT_TAG}_commitMSG | echo "OK"
	@git branch | grep -P '\* \d+\.\d+\.x' || (echo "You must be in a version branch" && exit 1)
	@#TODO: you must be on a branch that matches the version
	@#TODO: you must be synced with the remote branch

patch: test before-tag VERSION.txt
	@python -c "f = open('VERSION.txt'); a = f.read().strip('\r\n').split('.'); f.close(); c = [int(b) for b in a]; c[2] += 1; print '.'.join([str(d) for d in c])" > tmp; mv tmp VERSION.txt
	@echo "patch" > /tmp/.${PROJECT_TAG}_commitMSG
	@make create-tag

create-tag: /tmp/.${PROJECT_TAG}_commitMSG
	#never call this tag directly
	@git add VERSION.txt
	#TODO remove patch word from version tag...
	@cat VERSION.txt | xargs -I [] git commit -m "New ${PROJECT_NAME} patch version []"
	@cat VERSION.txt | xargs -I [] git tag -a v[] -m '${PROJECT_NAME} version []'
	@git branch | grep \* | cut -d' ' -f 2 | xargs git push origin
	@git push --tags
