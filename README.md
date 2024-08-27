# eri-easyconfigs
<p align="center" width="100%">
    <img width="20%" src="https://github.com/nesi/eri-easyconfigs/blob/main/resources/eri_hex.png"> 
</p>

AgR eRI cluster and OnDemand easybuild easyconfig files

## Workflow
**DO NOT PUSH TO GIT FROM eri-apps-admin**

### Set Up
First time easybuilders do the following to create the root of your easybuildinstall:
You only need to run this once
```
mkdir -p /agr/scratch/projects/2023-nesi_slurm_testing/$USER
cd /agr/scratch/projects/2023-nesi_slurm_testing/$USER
git clone https://github.com/nesi/eri-easyconfigs.git
```
### dev builds as your user:
Source the config file to setup EB:
```
cd /agr/scratch/projects/2023-nesi_slurm_testing/$USER/eri-easyconfigs 
source /agr/persist/apps/share/ebinit.sh
git pull
eb f/foo.eb
```
to test
```
module use /agr/scratch/projects/2023-nesi_slurm_testing/mattb/easybuildinstall/rocky8/modules/
<tool> --version # or more relevent tests
```
edit, build and test as user then push to repo

### Production builds
as `eri-apps-admin` user:
```
sudo -i -u eri-apps-admin
```

cd to build path and source as above
```
source /agr/persist/apps/share/ebinit.sh
cd /home/eri-apps-admin/eri-easyconfigs
git pull
```  

Build to the modules as production
```
eb foo.eb
```
The resulting `.lua` module is then available at `/agr/persist/apps/eri_rocky8/modules/all/<tool>/<tool.lua>`

### Apps Amin Directories
modules - `/agr/persist/apps/eri_rocky8/`  
containers - `/agr/persist/apps/containers/<name>/<name.sif>`  
databases - `/agr/persist/apps/databases/<name>/<version>`  

### Resources
RST Wiki with more complete software build notes and guides.
https://nznesi.atlassian.net/wiki/spaces/nesiproj/pages/504037498/Software+installs+on+Mahuika+M+ui+eRI

tool for simplyfying the update of R and Python modules
https://github.com/fizwit/easy_update
