#!/bin/bash
#SBATCH --job-name=compile      # Job name
#SBATCH --partition=cpu8358      # Partition name, Or cpu6348
#SBATCH --nodes=1                # Number of nodes
#SBATCH --ntasks-per-node=1      #
#SBATCH --qos=300cores           # Quality of Service (QOS) setting
#SBATCH --output=%j.out          # Standard output (%j will be replaced with the job ID)
#SBATCH --error=%j.error         # Standard error (%j will be replaced with the job ID)
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kenan.song@xjtlu.edu.cn

module purge
module load netlib-lapack/3.11.0-gcc-8.5.0-r63wfp7

gfortran -g -fbacktrace -fcheck=all TIGHTBINDINGFORGRAPHENE.f90 \
  -L/gpfs/spack/opt/linux-rocky8-icelake/gcc-8.5.0/netlib-lapack-3.11.0-r63wfp7u7ao47agcwi6ayecqkgm4qn77/lib64 \
  -llapack -lblas \
  -Wl,-rpath,/gpfs/spack/opt/linux-rocky8-icelake/gcc-8.5.0/netlib-lapack-3.11.0-r63wfp7u7ao47agcwi6ayecqkgm4qn77/lib64 \
  -o TIGHTBINDINGFORGRAPHENE

rm *.mod
