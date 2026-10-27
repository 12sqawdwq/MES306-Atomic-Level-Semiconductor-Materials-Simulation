#!/bin/bash

#SBATCH --job-name=examination   # Job name
#SBATCH --partition=cpu8358      # Partition name, Or cpu6348
#SBATCH --nodes=1                # Number of nodes
#SBATCH --ntasks-per-node=1      #
#SBATCH --qos=300cores           # Quality of Service (QOS) setting
#SBATCH --output=%j.out          # Standard output (%j will be replaced with the job ID)
#SBATCH --error=%j.error         # Standard error (%j will be replaced with the job ID)
#SBATCH --mail-type=ALL

module purge

export OMP_NUM_THREADS=1
ulimit -s unlimited
srun ./TIGHTBINDINGFORGRAPHENE
