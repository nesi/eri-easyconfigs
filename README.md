# eri-easyconfigs
<p align="center" width="100%">
    <img width="33%" src="eri_hex.png">
</p>

AgR eRI cluster and OnDemand easybuild easyconfig files

## Workflow

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
eb <alphabet>/foo.eb
```
to test
```
module use ../agr/scratch/projects/2023-nesi_slurm_testing/mattb/easybuildinstall/rocky8/modules/
<tool> --version # or more relevent tests
```
edit, build and test as user then push to repo

### Production builds
as `eri-apps-admin` user:
```
sudo -i -u eri-apps-admin
source /agr/persist/apps/share/ebinit.sh
cd /home/eri-apps-admin/eri-easyconfigs
```  
fetch/pull updates
```
eb foo.eb
```
**DO NOT PUSH TO GIT FROM eri-app-admin**

RST Wiki with more complete software build notes and guides.
https://nznesi.atlassian.net/wiki/spaces/nesiproj/pages/504037498/Software+installs+on+Mahuika+M+ui+eRI

