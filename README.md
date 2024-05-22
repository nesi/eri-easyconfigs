#easyconfigs
Easybuild easyconfig files for both Mahuika and the AgR eRI cluster.

Current setup is to have one directory for each cluster for easy of transfer builds between the two with the long term view that both clusters will have the same configuration and tools chanins.

## eRI Modules

### build as user first
```
source /agr/persist/apps/share/ebinit.sh   
cd /agr/scratch/projects/2023-nesi_slurm_testing/bixleym@agresearch.co.nz/eri-easyconfigs   
eb <themodule.eb>   
module use ../agr/scratch/projects/2023-nesi_slurm_testing/bixleym@agresearch.co.nz/easybuildinstall/rocky8/modules/bio   
```

push the update with relevant comments


### switch to apps admin
```
sudo -i -u eri-apps-admin   
source /agr/persist/apps/share/ebinit.sh   
cd /home/eri-apps-admin/eri-easyconfigs
```  

pull the repo
build the new module

####TODO:
fetch/pull updates

## Mahuika Modules
