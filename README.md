# nextstrainoomy
Documentation for the nextstrain software installed on the oomy webserver

## Oomy installation
The [nextstrain][https://nextstrain.org/] gitbub repository can be found freely
available [here][https://github.com/nextstrain] along with some installation
and usage [documentation][https://docs.nextstrain.org/en/latest/index.html].

Nextstrain was installed on the oomy webserver according to the local
installation [guide][https://docs.nextstrain.org/en/latest/guides/install/local-installation.html].
The conda environment created is stored locally on the oomy webserver and is
distinct from the CGRB conda environment. This distinction will be important
when the website is deployed for public use.


## Quickstart guide for Viewing nexstrain in a web browser
For now, the installed nextstrain website is only viewable to those who have
ssh access to the oomy webserver. To view the website in a local browser, one
needs to execute the following command on their local command line prompt
(not ssh'd into oomy):

`ssh -p 732 -N -L localhost:8890:localhost:8890 {username}@oomy.cgrb.oregonstate.edu`

where {username} is replaced by your oom account username. For instance, the
command for me is:

`ssh -p 732 -N -L localhost:8890:localhost:8890 tuppea@oomy.cgrb.oregonstate.edu`


The nextstrain website can then be viewed in a web browser by navigating to:

`localhost:8890`


The above ssh command must be allowed to run while viewing the website. Killing
the process will terminate viewability of the website in the browser. For
convenience, one can add the `-f` flag to the above ssh command to have it run
in the background, thus freeing up the terminal.


### Behind the scenes details
The nextstrain website is running on oomy using the following nextstrain
command, executed within the nextstrain conda environment, while in the
`/data/www/grunwaldlab_nextstrain/` directory:

`nextstrain view data/ --port 8890`

`nextstrain view` runs the auspice visual client for viewing the website.
`data/` is the location of the json data files for each lineage/species and
`--port 8890` is the designated local port for viewing the website in a
browser. Since oomy is a remote server, we cannot simply open up a chrome
browser on oomy to view the website. Instead, we had to forward the local
oomy port to a local machine for viewing, which is what the above ssh command
accomplishes. Note that this is only a temporary solution as port 8890 was
originally designated for running jupytor notebooks.



