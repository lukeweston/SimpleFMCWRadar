# Put in your GitHub account details.
GITHUB_USER=foo
GITHUB_API_TOKEN=foo

# Project name = directory name.
# TO DO: This variable seems to fail sometimes. Fix it.
#PROJECT_NAME=$${PWD\#\#*/}

PROJECT_NAME=SimpleFMCWRadar-RFBoard

# Gerbv PCB image preview parameters - colours, plus resolution.
GERBER_IMAGE_RESOLUTION?=400
BACKGROUND_COLOUR?=000000
HOLES_COLOUR?=000000
SILKSCREEN_COLOUR?=C4C4C4
PADS_COLOUR?=FFDE4E
TOP_SOLDERMASK_COLOUR?=630B79
BOTTOM_SOLDERMASK_COLOUR?=2D114A

# STUFF YOU WILL NEED:
# - git, gerbv and eagle must be installed and must be in path.
# - Got GitHub account?
# - GitHub set up with your SSH keys etc.
# - Put your GitHub username and private API key in the makefile

# On Mac OSX we will create a link to the Eagle binary:
# sudo ln -s /Applications/EAGLE/EAGLE.app/Contents/MacOS/EAGLE /usr/bin/eagle 

.SILENT: all gerbers git github clean

all : gerbers git github

.PHONY: gerbers

gerbers :

	mkdir -p gerbers
	mkdir -p temp
	for f in `ls *.s#* *.b#* 2> /dev/null`; do mv $$f ./temp/; done
	echo "Generating Gerber files..."
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GTL $(PROJECT_NAME).brd Top Pads Vias Dimension > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GBL $(PROJECT_NAME).brd Bottom Pads Vias > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GTO $(PROJECT_NAME).brd tPlace > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GTP $(PROJECT_NAME).brd tCream > /dev/null
#	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GBO $(PROJECT_NAME).brd bPlace > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GTS $(PROJECT_NAME).brd tStop > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GBS $(PROJECT_NAME).brd bStop > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GML $(PROJECT_NAME).brd Milling > /dev/null
	eagle -X -d GERBER_RS274X -o ./gerbers/$(PROJECT_NAME).GKO $(PROJECT_NAME).brd Dimension > /dev/null
	eagle -X -d EXCELLON -o ./gerbers/$(PROJECT_NAME).TXT $(PROJECT_NAME).brd Drills Holes > /dev/null
	zip $(PROJECT_NAME)-gerbers ./gerbers/*.*

image :
	
	`gerbv --export=png --output=$(PROJECT_NAME)-pcb.png --dpi=$(GERBER_IMAGE_RESOLUTION) --background=#$(BACKGROUND_COLOUR) --f=#$(HOLES_COLOUR) \
	gerbers/$(PROJECT_NAME).TXT --f=#$(SILKSCREEN_COLOUR) gerbers/$(PROJECT_NAME).GTO --f=#$(PADS_COLOUR) gerbers/$(PROJECT_NAME).GTS --f=#$(TOP_SOLDERMASK_COLOUR) \
	gerbers/$(PROJECT_NAME).GTL --f=#$(BOTTOM_SOLDERMASK_COLOUR) gerbers/$(PROJECT_NAME).GBL &`
	echo "Gerber photoplotter files and board preview rendering generated."
	
	if [ ! -e README.markdown ]; then echo "$(PROJECT_NAME) \n\n ![](https://github.com/$(GITHUB_USER)/$(PROJECT_NAME)/raw/master/$(PROJECT_NAME)-pcb.png)" >> \
	README.markdown; fi

# TO DO: Can we get Eagle to automatically export the schematic, as a PDF or PostScript or PNG, at the command line?

git : gerbers

	if [ ! -d .git ]; then git init > /dev/null; fi
	if [ -d ./gerbers ]; then git add ./gerbers; fi
	for f in `ls *.brd *.sch *.png *.pdf *.txt *.markdown .gitignore 2> /dev/null`; do git add $$f; done
	-git commit -m "foo" > /dev/null
	echo "Files committed to local git repository."

github : git

# TO DO: When we call the API to see if the repository exists, it cannot see your private repos unless the username and key is put in.
	
	-curl -f https://github.com/api/v2/yaml/repos/show/$(GITHUB_USER)/$(PROJECT_NAME) > /dev/null 2>&1; \
	if [ $$? -eq 0 ]; then echo "GitHub remote repository already exists."; fi

# TO DO: Known bug case - breaks if the GitHub repository exists but there is still a remote set for some reason in the local git repo.

	-curl -f https://github.com/api/v2/yaml/repos/show/$(GITHUB_USER)/$(PROJECT_NAME) > /dev/null 2>&1; if [ $$? -eq 22 ]; then \
	curl -F 'login=$(GITHUB_USER)' -F 'token=$(GITHUB_API_TOKEN)' https://github.com/api/v2/yaml/repos/create -F 'name=$(PROJECT_NAME)' > /dev/null 2>&1; \
	git remote add origin git@github.com:$(GITHUB_USER)/$(PROJECT_NAME).git; echo "Built new GitHub remote repository."; fi
	echo "Pushing to GitHub remote repository..."
	git push -u origin master 2> /dev/null
	echo "Done."

clean :
	rm -rf *.{GTL,GBL,GTO,GTP,GBO,GTS,GBS,GML,TXT,dri,gpi,png}
	rm -rf ./gerbers
	rm -rf .git

