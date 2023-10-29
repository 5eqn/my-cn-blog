.PHONY: sync
sync:
	hexo generate
	hexo deploy
	git add .
	git commit -m 'feat: new post'
	git push
