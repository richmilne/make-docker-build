# make-docker-build
A sample project showing how to use a Makefile to build and manage Docker containers.

## Typical usage

    make build
    make start
    make status
    make attach
    ^P^Q
    make stop

# Discussion

A typical Makefile exemplified by: {commit-id}

## Duplicated `docker ps` commands

As per the DRY principle, I'm not a fan of all the duplicated `docker ps ...` commands in the various targets (such as `start` and `attach`) And why the unusual `grep` construct? For example, look at the `start` target:

    start:
    # Run as a (background) service, or print ID if already running.
    ␉   @docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$ | grep $(CONTAINER_NAME) 1>/dev/null \
    ␉   && docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$ --format "{{.ID}}" \
    ␉   || docker run -d --rm...

The first part of the pipe,

    docker ps -a --no-trunc --filter name=^/$(CONTAINER_NAME)$$

is straightforward enough - it will print out the details of the container with `$(CONTAINER_NAME)`. Try it in the shell with:

    $ declare -x CONTAINER_NAME=aap_noot
    $ docker create --name "$CONTAINER_NAME" alpine:3.15
    $ docker ps -a --filter name=^/"${CONTAINER_NAME}"$
    CONTAINER ID  IMAGE        COMMAND     CREATED        STATUS   NAMES
    32a2396d2163  alpine:3.15  "/bin/sh"   2 minutes ago  Created  aap_noot

That's fine, when the container exists - but when it doesn't, Docker nevertheless returns a shell status code of 0 (success!):

    $ docker ps -a --filter name=^/"${CONTAINER_NAME}"$; echo "exit code: $?"
    exit code: 0
    $ docker ps -a --filter name=^/"mies"$; echo "exit code: $?"
    exit code: 0

So with this Docker command, we can't distinguish, in a shell pipeline, whether the container exists or not. The next part of the pipeline therefore uses `grep` to search for the container name and return a relevant exit code if it is or isn't found:

    $ docker ps -a --filter name=^/"${CONTAINER_NAME}"$ | grep "${CONTAINER_NAME}" 1>/dev/null; echo "exit code: $?"
    exit code: 0
    $ docker ps -a --filter name=^/"mies"$ | grep "${CONTAINER_NAME}" 1>/dev/null; echo "exit code: $?"
    exit code: 1

Only when `grep` returns success do we move on to the next stage (signified by `&&`), which is to invoke `docker ps` again to capture the ID of our container, now we know it exists.

There's a better Docker command for querying artifacts: `docker <artifact> inspect`:

    $ docker container inspect "${CONTAINER_NAME}" --format="{{.ID}}" 2>/dev/null; echo "exit code: $?"
    d387a3caa69b17566adf0af451798f0ea3fff7d6a8c9310495553a0d4eb942a6
    exit code: 0
    $ docker container inspect "mies" --format="{{.ID}}" 2>/dev/null; echo "exit code: $?"
    
    exit code: 1


Using Make's constructs, we can more easily try and capture the container's ID, and use Make's conditional syntax to determine whether to continue. First, set a Make variable to hold the container's ID:

    CONTAINER_ID != docker container inspect "$(CONTAINER_NAME)" --format="{{.ID}}" 2>/dev/null

Now we can test whether the variable has been set or not in the Makefile, and take action accordingly:

    start:
        # Run as a (background) service, or print ID if already running.
        ifdef CONTAINER_ID
        # Already running - print out ID
    ␉   ␉   @echo $(CONTAINER_ID)
        else
        # Start the container
    ␉   ␉   docker run -d --rm...
        endif

We can now also use the `start` target as a prerequisite for targets that require a running container, such as `attach`.

But there's another wrinkle - containers can be in several states, not just running. For example, if a container is stopped, the process outlined above won't restart it - and the `attach` target won't work as you can't `docker exec` in a stopped container.

We could make our approach more sophisticated by querying the containers state and varying our actions depending on what we find, but again there's a simpler way. Generally, we make sure our container's run options always include the `--rm` option, which ensures the container is removed when it exists. With only the options in our Makefile, then, the container can only exist in the `running` state.