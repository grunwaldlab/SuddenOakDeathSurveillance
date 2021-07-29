# nextstrainoomy
Documentation for the nextstrain software installed on the oomy webserver

## Oomy installation
The [nextstrain](https://nextstrain.org/) gitbub repository can be found freely
available [here](https://github.com/nextstrain) along with some installation
and usage [documentation](https://docs.nextstrain.org/en/latest/index.html).

Nextstrain was installed on the oomy webserver according to the local
installation [guide](https://docs.nextstrain.org/en/latest/guides/install/local-installation.html).
The conda environment created is stored locally on the oomy webserver and is
distinct from the CGRB conda environment. This distinction will be important
when the website is deployed for public use.


## Quickstart guide for viewing nexstrain in a web browser
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
originally designated for running jupyter notebooks. For convenience, I have
run the above command using `nohup` and redirected output to /dev/null which
should allow the program to run until I manually kill it.

#### Update
It appears that `nextstrain view` does not allow for narratives, which is odd
and likely an oversight. To get narratives to work, I had to work around this
by running auspice directly, which under the covers, nextstrain calls auspice
anyways.

`auspice view` allows for specifications of a data and narrative directory but
does not allow for specification of a port #. According to the nextstrain docs,
auspice respects the HOST and PORT environmental varriables. Therefore I ran
the following commands to first set the localhost and port, and then called
auspice view through nohup:

`export HOST=127.0.0.1`
`export PORT=8890`

`nohup auspice view --datasetDir=data/ --narrativeDir=narratives/ >/dev/null 2>/dev/null </dev/null &`

#### Update2
I added activate and deactivate scripts to
`/usr/local/webconda/master/nextstrain/etc/conda/` which automatically set
the $TMPDIR, $HOST, $PORT environmental variables so these no longer need to be
specified manually.


## Playing with nextstrain command line utilities
In addition to the website, nextstrain provides a few command line utilities
which can be used for building the website data files and some bioinformatic
analysis. To utilize this, one must be logged into the oomy webserver.

Nextstrain was installed according to the conda environment guidelines which
means that the command line utilities are only available within the nextstrain
conda environment. The following instructions may differ depending on whether
conda has been used previously on CGRB.

When logged into oomy, one should first attempt to view the available conda
environments within bash using the following commands. First login to a bash
shell:

`bash`

Then view the available conda environments:

`conda env list`

If an error messsage is reported allong the lines of: "Your shell has not been
properly configured to use conda ...", one needs to first run:

`conda init bash`

This will initialize the conda environment and update the users .bashrc file
such that the conda environment list are known upon login.
You may need to restart the terminal session for the effects to become active.

Assuming no error was reported, one should see a list of environments with
names and locations. Paths which start with `/local/cluster/miniconda2` are
global for all CGRB resources. The nextstrain install is local to oomy and so
we are looking for: `/usr/local/webconda/master/nextstrain`. If this is your
first time attempting this you will likely not see this entry. This is because
conda does not know where to look. To have conda search the correct paths, run:

`source /usr/local/webconda/master/bin/activate`

Re-running `conda env list` should now display
`/usr/local/webconda/master/nextstrain`. To enter the nextstrain conda
environment, we run:

`conda activate /usr/local/webconda/master/nextstrain`

This will activate the conda environment and one should now be able to run
the nextstrain command line utities. For instance:

`nextstrain -h`


