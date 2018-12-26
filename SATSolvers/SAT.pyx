import random
import numpy as np
cimport numpy as np
cimport cython
from libc.math cimport exp

from cpython cimport array
from libc.stdlib cimport rand, RAND_MAX
from collections import deque
import time
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free



@cython.boundscheck(False)
@cython.cdivision(True)
def GSAT(clause, n_v):
    cdef int n_var
    n_var = n_v
    cdef np.ndarray[np.int64_t, ndim=1] variables = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] g_sat_comp = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] rand_to_do = np.zeros(n_var, dtype=np.int64)


    cdef int i, j, k, tmp, max, ind, id
    cdef int n_clauses, cnt, max_iter
    max_iter = 20
    cnt = 0
    n_clauses = int(len(clause))

    cdef int ** clauses = <int **>PyMem_Malloc(n_clauses*sizeof(int*))

    for i in range(n_clauses):
        tmp = len(clause[i])
        clauses[i] = <int *>PyMem_Malloc((tmp+1)*sizeof(int))
        clauses[i][0] = tmp
        for j in range(tmp):
            clauses[i][j+1] = clause[i][j]

    for i in range(n_var):
        variables[i] = rand() % 2

    while True:
        if cnt > max_iter:
            return "Can't find solution"

        if satisfied_clauses(clauses, variables, n_clauses) == n_clauses:
            return variables

        for i in range(n_var):
            g_sat_comp[i] = bad_to_good_after_flip(clauses, variables,
                                                   i, n_clauses) - good_to_bad_after_flip(clauses, variables,
                                                                                          i, n_clauses)

        max = 0
        ind = 0
        id = 0
        print(g_sat_comp)
        for i in range(n_var):
            if g_sat_comp[i] > max:
                rand_to_do.fill(0)
                id = 1
                rand_to_do[0] = i
                max = g_sat_comp[i]
                ind = i
                continue
            if g_sat_comp[i] == max:
                rand_to_do[id] = i
                id += 1
                ind = -1
                #append
        print(rand_to_do, "    rnd")
        print(variables)

        print("iiiiidddd: ", ind)
        #if variables[ind] == 1:
        #    variables[ind] = 0
        #else:
        #    variables[ind] = 1

        cnt += 1
        satisfied_clauses(clauses, variables, n_clauses)
        print("Iter:", cnt)
        print("-------------------------------")

    return variables


@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
cdef int bad_to_good_after_flip(int ** clauses, np.int64_t[:] variables, int var, int n_clauses):
    cdef int cnt, kill, bad, i, j
    cnt = 0
    kill = 0
    bad = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if var == abs(clauses[i][j+1]):
                kill = 1
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 0:
                bad += 1
            elif clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 1:
                bad += 1
        if kill == 1 and bad == 0:
            for j in range(clauses[i][0]):
                if var == abs(clauses[i][j+1]) and clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 1:
                    cnt += 1
                elif var == abs(clauses[i][j+1]) and clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 0:
                    cnt += 1
        else:
            kill = 0
            bad = 0
    return cnt

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
cdef int good_to_bad_after_flip(int ** clauses, np.int64_t[:] variables, int var, int n_clauses):
    cdef int cnt, kill, good, i, j, bad
    cnt = 0
    kill = 0
    good = 0
    bad = 0
    for i in range(n_clauses):
        # check if is satisfied and contain variable
        for j in range(clauses[i][0]):
            if var == abs(clauses[i][j+1]):
                kill = 1
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 0:
                good += 1
            elif clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 1:
                good += 1
        if kill == 1 and good > 0:
            # check with flip
            for j in range(clauses[i][0]):
                if var == abs(clauses[i][j+1]) and clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 1:
                    bad += 1
                elif var == abs(clauses[i][j+1]) and clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 0:
                    bad += 1
                elif clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 0:
                    bad += 1
                elif clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 1:
                    bad += 1
            if bad == 0:
                cnt += 1
        kill = 0
        good = 0
        bad = 0
    return cnt

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
cdef int satisfied_clauses(int ** clauses, np.int64_t[:] variables, int n_clauses):
    cdef int cnt, i, j
    cnt = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])] == 0:
                cnt += 1
                break
            if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])] == 1:
                cnt += 1
                break
    print(cnt, " satisfied")
    return cnt
