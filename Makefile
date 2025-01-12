.PHONY: all
all:
	hexo generate
	hexo deploy
	git add .
	git commit -m ':pencil: new post'
	git push
