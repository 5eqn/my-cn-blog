.PHONY: sync
sync:
	hexo generate
	hexo deploy
	git commit -m 'feat: new post'
	git push
