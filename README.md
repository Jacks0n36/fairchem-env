# fairchem-env

Installation
------------

1. In a computing environment with singularity configured, set up an sbatch script that can (or from an interactive compute job) run
  ```commandline
  cd $SCRATCH
  module load WebProxy
  singularity pull --disable-cache container.sif docker://ghcr.io/jacks0n36/fairchem-env:server
  ```
Note: if you only want the fairchem conda environment configured in a container, substitute the tag `main` in for `server` on the tail of the ghrc.io url. Then, skip to [this subsection](#Container-with-only-the-conda-environment).
  - You should avoid using tag `latest`; this tag can be written to by both of the container variants.
2. You will also need to clone the repository `github.com/jacks0n36/mlipenv`. It's a good idea to `cd $HOME` before cloning the repo. But, as long as you know where the cloned repo is in your file system, you should be fine.
    - this repository exposes the script `mlip_server.py`, which we will use to talk to the server at runtime.

Server Configuration
--------------------

- The main purpose of the server is to have a low-cost entry point to our MLIP during the execution of a script that makes repeated calls to that MLIP.
1. The default port that the server listens on is `27182`. This can be changed to an arbitrary valid port, `port`, by setting
```
$ MLIP_SOCKET_PORT=port
```
Note: It is often convenient to use `export MLIP_SOCKET_PORT=port` so that the environment variable persists in subshell calls.
2. With the socket port configured, we background the server using
```
$ singularity run container.sif &
```
3. Now, the server is configured and listening for requests.

Runtime
-------
1. In any process that is running on the same machine as the server is backgrounded on, ensure that `MLIP_SOCKET_PORT` is set to match that of the server's.
    - If you are running from a process unrelated to the one running the server, you will have to set this environment variable. Recall that, with the defaults, this means that you will need to set
```
$ MLIP_SOCKET_PORT=27182
```
2. Also, ensure that your runtime process can execute python scripts. `mlip_server.py` uses only the standard library, so any relatively modern version of python should be sufficient.
3. In order to talk to the server, we then execute a command in the form
```
$ python ~/mlipenv/mlip_server.py [keyword] [args]
```
- If you cloned the `mlipenv` repo to some exotic location, replace `~/mlipenv/mlip_server.py` with your `[/path/to/]mlipenv/mlip_server.py`

# Keywords
- There are two keywords, `exit` and `evaluate`, that the server is configured to listen for:
1. `exit`:
- shuts the server down
- usage:
```
python ~/mlipenv/mlip_server.py exit
```
2. `evaluate`:
- uses fairchem to run computations
- takes in a single additional argument that should point to a JSON file structuring the type of computation that you are requesting, parameters for the model, and locations for your atoms/coordinates. The next section details how this JSON configuration file should be structured.
- usage:
```
python ~/mlipenv/mlip_server.py evaluate config.json
```
- note: make sure that your configuration file parameter points to a valid path to a file. If the config lives somewhere thats not in your working directory, replace `config.json` with `[/path/to/]config.json`.

Runtime config
--------------
1. There are utility scripts that should help with configuration building located under the `notebooks` folder. For an enumeration of all of the configuration parameters, read on.


The top-level parameters in the configuration file are:

|Parameters|Type|Description|
|---|---|---|
|`method`|`string`|can be specified as either `optimize` for a geometry optimization or `energy` for just an energy computation.|
|`options`|`dictionary`|a table of arguments that are specific to the `method` chosen.|
|`atoms`|`string`|a path to a list or lists of atom symbols. if possible, you should write to an `.npz` file.|
|`coordinates`|`string`|a path to a list or lists of atomic coordinates. if possible, you should write to an `.npz` file.|
|`charge`|`int` or `list[int]`|the charge for each structure input into the model. if you only provide a single charge but have multiple structures, it is assumed that all structures have that charge.|
|`spin`|`int` or `list[int]`|the spin multiplicity for each structure input into the structures. if you only provide one for multiple structures, it is assumed that all structures have that spin multiplicity.|
|`output_dir`|`string`|the location where outputs will be written to. defaults to the running directory.|

### `options` for method
For `method=optimization`, the following parameters can be placed inside of the `options` table:

|Parameters|Type|Description|
|---|---|---|
|`optimizer`|`string`|optimizer used in energy minimization. currently, only `ase` is implemented, running an LBFGS search.|
|`options`|`dictionary`|a table of arguments specific to the chosen `optimizer`.|


### `options` for ase optimizer
For `optimizer=ase`, the following parameters can be placed inside of this inner-most `options` table:

|Parameters|Type|Description|
|---|---|---|
|`fmax`|`float`|optimization convergence criteria: converges when all forces have magnitude less than `fmax`. the default is 0.02.|
|`steps`|`int`|the upper bound number of optimization steps that will be taken.|
|`logging`|`string`|path to where logging and trajectory files for the optimizations will be sent. by default, logging is sent to console and trajectory files are not written.|
|`output`|`string` or `list[string]`|optimized parameters that will be written as output. options include `atoms`, `coordinates`, `gradients`, and `energies`. defaults to writing everything.|

Container with only the conda environment
-----------------------------------------
The entrypoint for this container reads
```
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "fairchem"]
```
In other words, for example,
```
singularity run container.sif python script.py
```
expands to
```
conda run --no-capture-output -n fairchem python script.py
```
where fairchem is the name of the conda environment. Think of this container as a substitute for building the conda environment for fairchem on disk, and its usage as a substitute for running that disk-bound conda environment.
