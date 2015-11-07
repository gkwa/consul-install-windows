PS_SW=
PS_SW+=-version 3
PS_SW+=-noprofile
PS_SW+=-executionpolicy unrestricted

install:
	powershell $(PS_SW) -file nssminstall.ps1
	powershell $(PS_SW) -file consulinstall.ps1

readme: README.md
README.md: README.org
	docker run -v `pwd`:/source jagregory/pandoc --from=org --to=markdown --output=$@ $<
	doctoc --title 'consul-install-windows' $@
