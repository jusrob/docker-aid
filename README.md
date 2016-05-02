# docker-aid

Tool designed to help with the management of single docker host

###Usage:

######Show run command for container
`docker-aid.rb -c mycontainer -s`

######List info about conatiner
`docker-aid.rb -c mycontainer -l`

######Refresh container with newest version
`docker-aid.rb -c mycontainer -r`

######Force refresh container with newest version
`docker-aid.rb -c mycontainer -r -f`

```
Usage: dockerauto.rb -c[--container] <container name or id> [options]
    -c, --container NAME or ID       Container to run on
    -s, --showcommand                Show run command
    -l, --list                       List container info
    -r, --refresh                    Refresh container if needed
    -f, --force                      Force refresh of container
```
