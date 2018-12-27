import click
import time
from SAT import GSAT, WALKSAT


"""	Solve and test and stats instances with simulated anealing"""
@click.command()
@click.option('-f', '--file', type=click.File(), help="File with instance of problem in DIMACS format.", required=True)
@click.option('-a', '--alg', required=True)
def SATSolver(file, alg):
	lines = file.read().split("\n")
	clause = []
	cnt = 0
	n_c = 0
	for i in lines:
		if len(i) < 1: continue
		if i[0].strip() == 'c':
			continue
		if i[0].strip() == 'p':
			ind, problem, n_v, n_c = i.split()
			if problem.lower() != 'cnf':
				print('Can\'t solve not cnf problem')
				return
			n_v = int(n_v)
			n_c = int(n_c)
			continue
		clause.append([int(j) for j in i.split()[:-1]])
		cnt += 1
		if cnt >= n_c:
			break
	if str(alg).lower() == 'gsat':
		t1 = time.time()
		solution = GSAT(clause, n_v, 2000, 0.4)
		print("GSAT sollution time:", time.time()-t1, 's. Var number:', n_v, "Cls number:", n_c)
		print(solution)
		return
	if str(alg).lower() == 'walksat':
		t1 = time.time()
		solution = WALKSAT(clause, n_v, 2000, 0.4)
		print("WALKSAT sollution time:", time.time()-t1, 's. Var number:', n_v, "Cls number:", n_c)
		print(solution)
		return

if __name__ == '__main__':
	SATSolver()
