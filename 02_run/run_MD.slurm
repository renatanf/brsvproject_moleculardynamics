#!/bin/bash
#SBATCH --job-name=MD_L_kaemp         # Nome do trabalho
#SBATCH --output=MD_L_%j.log         # Arquivo de log geral (%j coloca o ID do trabalho)
#SBATCH --partition=bullet             # Fila correta de GPU do Pete que estava no seu print
#SBATCH --nodes=1                      # 1 no de computacao
#SBATCH --ntasks-per-node=1            # 1 tarefa principal
#SBATCH --gres=gpu:1                   # 1 Placa de Video (GPU)
#SBATCH --time=72:00:00                # Tempo limite: 72 horas (para garantir que os 50ns rodem com folga)

# 1. Carregar o software AMBER 
module load amber

# 2. Definir o nome base dos arquivos para facilitar
SYS="BRSV_L_kaempferol_solvated"

echo "====================================================="
echo " INICIANDO A DINAMICA MOLECULAR - COMPLEXO L+KAEMP"
echo "====================================================="

echo ">>> 1. MINIMIZACAO <<<"
pmemd.cuda -O \
  -i min.in \
  -p ${SYS}.prmtop \
  -c ${SYS}.inpcrd \
  -ref ${SYS}.inpcrd \
  -o ${SYS}_min.out \
  -r ${SYS}_min.rst \
  -inf ${SYS}_min.mdinfo

echo ">>> 2. AQUECIMENTO (0 a 310 K) <<<"
# Note que o input (-c) e a referencia (-ref) agora pegam o resultado (rst) da minimizacao!
pmemd.cuda -O \
  -i heat.in \
  -p ${SYS}.prmtop \
  -c ${SYS}_min.rst \
  -ref ${SYS}_min.rst \
  -o ${SYS}_heat.out \
  -r ${SYS}_heat.rst \
  -x ${SYS}_heat.nc \
  -inf ${SYS}_heat.mdinfo

echo ">>> 3. EQUILIBRACAO (NPT - Pressao Constante) <<<"
# O input (-c) pega o resultado do aquecimento. Nao tem mais '-ref' pois tiramos as amarras!
pmemd.cuda -O \
  -i eq.in \
  -p ${SYS}.prmtop \
  -c ${SYS}_heat.rst \
  -o ${SYS}_eq.out \
  -r ${SYS}_eq.rst \
  -x ${SYS}_eq.nc \
  -inf ${SYS}_eq.mdinfo

echo ">>> 4. PRODUCAO (50 ns) <<<"
pmemd.cuda -O \
  -i prod.in \
  -p ${SYS}.prmtop \
  -c ${SYS}_eq.rst \
  -o ${SYS}_prod.out \
  -r ${SYS}_prod.rst \
  -x ${SYS}_prod.nc \
  -inf ${SYS}_prod.mdinfo

echo "====================================================="
echo " SIMULACAO CONCLUIDA COM SUCESSO! "
echo "====================================================="