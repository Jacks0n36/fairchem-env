FROM continuumio/miniconda3:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install git gcc g++ && \
    rm -rf /var/lib/apt/lists/*

COPY fairchem.yml .

RUN conda env create -f fairchem.yml && \
    conda clean --all -afy

# Install pip manually in case it is missing in the environment
RUN conda run -n mace python -m ensurepip --upgrade
RUN conda run -n mace python -m pip install --upgrade pip setuptools wheel

ENV PATH=/opt/conda/bin:$PATH

# Set the default shell to use bash and activate the conda environment
ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "fairchem"]
