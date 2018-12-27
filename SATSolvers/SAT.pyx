import random
import numpy as np
cimport numpy as np
cimport cython
from libc.math cimport exp

from cpython cimport array
from libc.stdlib cimport rand, RAND_MAX
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

@cython.boundscheck(False)
cdef int** loadANDinit(clause, int n_clauses, np.int64_t[:] variables, int n_var):

    cdef int tmp, i, j
    cdef int ** clauses = <int **>PyMem_Malloc(n_clauses*sizeof(int*))

    for i in range(n_clauses):
        tmp = len(clause[i])
        clauses[i] = <int *>PyMem_Malloc((tmp+1)*sizeof(int))
        clauses[i][0] = tmp
        for j in range(tmp):
            clauses[i][j+1] = clause[i][j]

    for i in range(n_var):
        variables[i] = rand() % 2

    return clauses

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
def GSAT(clause, n_v, max_it, prob):

    cdef int n_var
    n_var = n_v
    cdef np.ndarray[np.int64_t, ndim=1] variables = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] g_sat_comp = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] rand_to_do = np.zeros(n_var, dtype=np.int64)

    cdef int i, j, max, ind, id, make, brake, n_clauses, counter, max_iter, satis
    n_clauses = int(len(clause))
    max_iter = max_it
    counter = 0

    cdef int ** clauses = loadANDinit(clause, n_clauses, variables, n_var)

    while True:
        if counter > max_iter:
            return "Can't find solution"

        satis = satisfied_clauses(clauses, variables, n_clauses)
        if satis == n_clauses:
            return variables

        for i in range(n_var):
            make = bad_to_good_after_flip(clauses, variables, i, n_clauses)
            brake = good_to_bad_after_flip(clauses, variables, i, n_clauses)
            g_sat_comp[i] = make - brake

        max = -n_clauses
        ind = 0
        id = 0
        for i in range(n_var):
            if g_sat_comp[i] > max:
                id = 1
                rand_to_do[0] = i
                max = g_sat_comp[i]
                continue
            if g_sat_comp[i] == max:
                rand_to_do[id] = i
                id += 1

        ind = rand_to_do[rand() % id]

        if rand()/<float>RAND_MAX < prob:
            ind = rand()%n_var


        if variables[ind] == 1:
            variables[ind] = 0
        else:
            variables[ind] = 1
        counter += 1
        print("Iter:", counter, " Satisfied:", satis)

    return variables


@cython.boundscheck(False)
cdef int bad_to_good_after_flip(int ** clauses, np.int64_t[:] variables, int var, int n_clauses):
    cdef int cnt, kill, bad, i, j
    cnt = 0
    kill = 0
    bad = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if var == (abs(clauses[i][j+1])-1):
                kill = 1
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])-1] == 0:
                bad += 1
            if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])-1] == 1:
                bad += 1
        if kill == 1 and bad == 0:
            cnt += 1
        kill = 0
        bad = 0
    return cnt

@cython.boundscheck(False)
cdef int good_to_bad_after_flip(int ** clauses, np.int64_t[:] variables, int var, int n_clauses):
    cdef int cnt, kill, good, i, j, bad
    cnt = 0
    kill = 0
    good = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if var == (abs(clauses[i][j+1])-1):
                if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])-1] == 0:
                    kill = 1
                if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])-1] == 1:
                    kill = 1
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])-1] == 0:
                good += 1
            if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])-1] == 1:
                good += 1
        if kill == 1 and good == 1:
            cnt += 1
        kill = 0
        good = 0
    return cnt

@cython.boundscheck(False)
cdef int satisfied_clauses(int ** clauses, np.int64_t[:] variables, int n_clauses):
    cdef int cnt, i, j
    cnt = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])-1] == 0:
                cnt += 1
                break
            if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])-1] == 1:
                cnt += 1
                break
    return cnt
