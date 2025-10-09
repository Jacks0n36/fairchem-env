FROM continuumio/miniconda3:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install git gcc g++ && \
    rm -rf /var/lib/apt/lists/*

COPY environment.yml .
RUN conda env create -f environment.yml && \
    conda clean --all -afy

ENV PATH=/opt/conda/bin:$PATH

ENTRYPOINT ["conda", "run", "--no-capture-output", "-n", "fairchem"]
