# Nothin' but Terraform

![Hashicorp Terraform][terraform-img]

## But Why Though

I needed a minimal installation of [hashicorp/terraform][terraform-src], downloaded and verified from the [official Terraform downloads][terraform-bin] page. This serves as a simple, containerized installation source.

## Docker

Please notice that the examples below do not specify image tags which means the Docker client will assume `latest`.

### Container

The Terraform executable is statically compiled and set as the image entry [`ENTRYPOINT`][dockerfile-entrypoint] with `help` as the default `CMD`:

```bash
# this container is not shipped with ca-certificates, so let's set those up (version check and plugin discovery+download)
docker container run --rm -it -v ca-certificates:/etc/ssl/certs alpine apk add --no-cache ca-certificates
# now we can invoke terraform
docker container run --rm -it -v ca-certificates:/etc/ssl/certs -v /tmp -v $PWD:$PWD -w $PWD overneath/terraform # [init|plan|apply|destroy|...]
```

```console
Usage: terraform [-version] [-help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
    destroy            Destroy Terraform-managed infrastructure
    env                Workspace management
    fmt                Rewrites config files to canonical format
    get                Download and install modules for the configuration
    graph              Create a visual graph of Terraform resources
    import             Import existing infrastructure into Terraform
    init               Initialize a Terraform working directory
    output             Read an output from a state file
    plan               Generate and show an execution plan
    providers          Prints a tree of the providers used in the configuration
    refresh            Update local state file against real resources
    show               Inspect Terraform state or plan
    taint              Manually mark a resource for recreation
    untaint            Manually unmark a resource as tainted
    validate           Validates the Terraform files
    version            Prints the Terraform version
    workspace          Workspace management

All other commands:
    0.12upgrade        Rewrites pre-0.12 module source code for v0.12
    debug              Debug output management (experimental)
    force-unlock       Manually unlock the terraform state
    push               Obsolete command for Terraform Enterprise legacy (v1)
    state              Advanced state management
```

```bash
docker container run --rm -it -v ca-certificates:/etc/ssl/certs -v /tmp overneath/terraform -version
```

```console
Terraform v0.12.5
```

Note the `-v /tmp` is important because the current default behavior of Terraform is to `exec` itself to capture logs.
Running vanilla Terraform in a container lacking a `/tmp` directory will error, e.g.:

```bash
docker container run --rm -it -v ca-certificates:/etc/ssl/certs overneath/terraform -version
```

```console
Couldn't setup logging tempfile: open /tmp/terraform-log076603776: no such file or directory
```

### Dockerfile

To install into an image via `Dockerfile`:

```dockerfile
COPY --from=overneath/terraform /opt/local/ /usr/local/
```

### Volume

To install into a container via `docker volume` leveraging (the default) [`nocopy=false`][docker-volume] behavior:

```bash
# this only works if the volume `terraform-files` does not already exist or it is empty
docker container run --rm --mount source=terraform-files,destination=/opt/local,volume-nocopy=false overneath/terraform
docker container run --rm -it --volume terraform-files:/usr/local alpine terraform help
```

---

[terraform-img]: https://avatars1.githubusercontent.com/u/28900900?s=192 "Hashicorp Terraform"
[terraform-bin]: https://www.terraform.io/downloads.html "Terraform Downloads"
[terraform-src]: https://github.com/hashicorp/terraform "Terraform on Github"
[docker-volume]: https://docs.docker.com/engine/reference/run/#volume-shared-filesystems "Docker Volume (shared filesystems)"
[dockerfile-entrypoint]: https://docs.docker.com/engine/reference/builder/#entrypoint "Dockerfile ENTRYPOINT"
