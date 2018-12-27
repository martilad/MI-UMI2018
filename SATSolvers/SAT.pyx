# distutils: language=c++
# defining NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION

import numpy as np
cimport numpy as np
cimport cython
from libcpp.map cimport map
from libc.stdlib cimport rand, RAND_MAX
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free


@cython.boundscheck(False)
cdef int** loadANDinit(clause, int n_clauses, np.int64_t[:] variables, int n_var):

    cdef int tmp, i, j, temp
    cdef int ** clauses = <int **>PyMem_Malloc(n_clauses*sizeof(int*))

    for i in range(n_clauses):
        tmp = len(clause[i])
        clauses[i] = <int *>PyMem_Malloc((tmp+1)*sizeof(int))
        clauses[i][0] = tmp
        for j in range(tmp):
            clauses[i][j+1] = clause[i][j]

    return clauses

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
def WALKSAT(clause, n_v, max_trie, max_it, probability):

    cdef int n_var
    n_var = n_v
    cdef np.ndarray[np.int64_t, ndim=1] variables = np.zeros(n_var, dtype=np.int64)
    cdef double prob = probability
    cdef int i, j, k, n_clauses, counter, max_iter, c_unsatisfied, ind, var, act_var, min, max_tri, clause_to_do
    n_clauses = int(len(clause))
    max_iter = max_it

    max_tri = max_trie


    cdef int ** clauses = loadANDinit(clause, n_clauses, variables, n_var)

    cdef np.ndarray[np.int64_t, ndim=1] unsatisfied_clauses = np.zeros(n_clauses, dtype=np.int64)

    for k in range(max_tri):
        counter = 0
        for i in range(n_var):
            variables[i] = rand() % 2
        while True:

            if counter > max_iter:
                break

            satis = satisfied_clauses(clauses, variables, n_clauses)

            if satis == n_clauses:
                return variables

            if rand()/<float>RAND_MAX < prob:
                ind = rand()%n_var
            else:
                c_unsatisfied = get_unsatisfied(clauses, variables, n_clauses, unsatisfied_clauses)
                clause_to_do = unsatisfied_clauses[rand() % c_unsatisfied]

                min = n_clauses
                c_unsatisfied = 0
                for i in range(clauses[clause_to_do][0]):
                    act_var = good_to_bad_after_flip(clauses, variables, abs(clauses[clause_to_do][i+1])-1, n_clauses)
                    if min > act_var:
                        min = act_var
                        unsatisfied_clauses[0] = abs(clauses[clause_to_do][i+1])-1
                        c_unsatisfied = 1
                        continue
                    if min == act_var:
                        unsatisfied_clauses[c_unsatisfied] = abs(clauses[clause_to_do][i+1])-1
                        c_unsatisfied += 1

                ind = unsatisfied_clauses[rand() % c_unsatisfied]

            if variables[ind] == 1:
                variables[ind] = 0
            else:
                variables[ind] = 1
            counter += 1

            #print("Iter:", counter, " Satisfied:", satis)


    return "Can't find solution"

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
def WALKSATW(clause, n_v, max_trie, max_it, probability):

    cdef int n_var
    n_var = n_v
    cdef np.ndarray[np.int64_t, ndim=1] variables = np.full(n_var,-1, dtype=np.int64)

    cdef int i, j, k, n_clauses, counter, max_iter, c_unsatisfied, ind, var, act_var, min, max_tri, clause_to_do, coIND, ch
    cdef double prob = probability
    n_clauses = int(len(clause))
    max_iter = max_it
    cdef map[int, int] to_set
    max_tri = max_trie
    coIND = 0
    ch = 1


    cdef int ** clauses = loadANDinit(clause, n_clauses, variables, n_var)

    cdef np.ndarray[np.int64_t, ndim=1] unsatisfied_clauses = np.zeros(n_clauses, dtype=np.int64)


    cdef map[int,map[int, int]] watch

    for k in range(max_tri):
        counter = 0
        for i in range(n_clauses):
            if clauses[i][0] == 1:
                if clauses[i][1] < 0:
                    variables[abs(clauses[i][1])-1] = 0
                else:
                    variables[abs(clauses[i][1])-1] = 1
            else:
                watch[abs(clauses[i][1])-1][i] = clauses[i][1]
                watch[abs(clauses[i][2])-1][i] = clauses[i][2]

        while True:

            if counter > max_iter:
                break

            satis = satisfied_clauses(clauses, variables, n_clauses)

            if satis == n_clauses:
                return variables

            if rand()/<float>RAND_MAX < prob and coIND != 1:
                ind = rand()%n_var
            else:
                coIND = 0
                c_unsatisfied = get_unsatisfied(clauses, variables, n_clauses, unsatisfied_clauses)
                clause_to_do = unsatisfied_clauses[rand() % c_unsatisfied]

                min = n_clauses
                c_unsatisfied = 0
                for i in range(clauses[clause_to_do][0]):
                    act_var = good_to_bad_after_flip(clauses, variables, abs(clauses[clause_to_do][i+1])-1, n_clauses)
                    if min > act_var:
                        min = act_var
                        unsatisfied_clauses[0] = abs(clauses[clause_to_do][i+1])-1
                        c_unsatisfied = 1
                        continue
                    if min == act_var:
                        unsatisfied_clauses[c_unsatisfied] = abs(clauses[clause_to_do][i+1])-1
                        c_unsatisfied += 1
                ind = unsatisfied_clauses[rand() % c_unsatisfied]

            if variables[ind] == 1:
                variables[ind] = 0
            else:
                variables[ind] = 1

            while True:
                if ch == 0:
                    break
                ch = 0
                to_set = check_watch_propag(clauses, variables, ind, 0, watch)
                for ein, zwe in to_set:
                    if zwe != -1:
                        variables[ein] = zwe
                        ch = 1
                    else:
                        coIND = 1

            counter += 1
            #print("Iter:", counter, " Satisfied:", satis)


    return "Can't find solution"

@cython.boundscheck(False)
@cython.cdivision(True)
cdef map[int, int] check_watch_propag(int ** clauses, np.int64_t[:] variables, ind, set, map[int,map[int, int]] watch):
    cdef map[int, int] to_set
    cdef ch = 0, state = 0, sett
    for i in [j for j in watch[ind]]:
        if i[1] == 0: continue
        if set == 1 and i[1] < 0:
            watch[ind][i[0]] = 0
            for j in range(clauses[i[0]][0]):
                if abs(watch[abs(clauses[i[0]][j+1])-1][i[0]]) == 1:
                    if state == 0:
                        state = 1
                        sett = clauses[i[0]][j+1]
                else:
                    if state <= 1 and ((variables[abs(clauses[i[0]][j+1])-1] == 0 and clauses[i[0]][j+1]<0)
                                       or (variables[abs(clauses[i[0]][j+1])-1] == 1 and clauses[i[0]][j+1]>0)):
                        state = 2
                        sett = clauses[i[0]][j+1]
                    if state <=2 and variables[abs(clauses[i[0]][j+1])-1] == -1:
                        state = 3
                        sett = clauses[i[0]][j+1]
            if state == 1:
                if sett < 0:
                    to_set[abs(sett)-1] = 0
                else:
                    to_set[abs(sett)-1] = 1
            if state == 0:
                to_set[i[0]] = -1
            if state > 1:
                watch[abs(sett)-1][i[0]] = sett

        if set == 0 and i[1] > 0:
            watch[ind][i[0]] = 0
            for j in range(clauses[i[0]][0]):
                if abs(watch[abs(clauses[i[0]][j+1])-1][i[0]]) == 1:
                    if state == 0:
                        state = 1
                        sett = clauses[i[0]][j+1]
                else:
                    if state <= 1 and ((variables[abs(clauses[i[0]][j+1])-1] == 0 and clauses[i[0]][j+1]<0)
                                       or (variables[abs(clauses[i[0]][j+1])-1] == 1 and clauses[i[0]][j+1]>0)):
                        state = 2
                        sett = clauses[i[0]][j+1]
                    if state <= 2 and variables[abs(clauses[i[0]][j+1])-1] == -1:
                        state = 3
                        sett = clauses[i[0]][j+1]
            if state == 1:
                if sett < 0:
                    to_set[abs(sett)-1] = 0
                else:
                    to_set[abs(sett)-1] = 1
            if state == 0:
                to_set[i[0]] = -1
            if state > 1:
                watch[abs(sett)-1][i[0]] = sett
    return to_set

@cython.boundscheck(False)
@cython.cdivision(True)
@cython.wraparound(False)
def GSAT(clause, n_v, max_trie, max_it, probability):

    cdef int n_var
    n_var = n_v
    cdef np.ndarray[np.int64_t, ndim=1] variables = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] g_sat_comp = np.zeros(n_var, dtype=np.int64)
    cdef np.ndarray[np.int64_t, ndim=1] rand_to_do = np.zeros(n_var, dtype=np.int64)

    cdef int i, j, k, max, ind, id, make, brake, n_clauses, counter, max_iter, satis, max_tri
    n_clauses = int(len(clause))
    max_iter = max_it
    cdef double prob = probability
    max_tri = max_trie
    cdef int ** clauses = loadANDinit(clause, n_clauses, variables, n_var)

    for k in range(max_tri):
        counter = 0
        for i in range(n_var):
            variables[i] = rand() % 2
        while True:
            if counter > max_iter:
                break

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
            #print("Iter:", counter, " Satisfied:", satis)

    return "Can't find solution"


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

@cython.boundscheck(False)
cdef int get_unsatisfied(int ** clauses, np.int64_t[:] variables, int n_clauses, np.int64_t[:] unsatisfied):
    cdef int cnt, i, j, uns, kill
    cnt = 0
    kill = 0
    uns = 0
    for i in range(n_clauses):
        for j in range(clauses[i][0]):
            if clauses[i][j+1] < 0 and variables[abs(clauses[i][j+1])-1] == 0:
                cnt += 1
                kill = 1
                break
            if clauses[i][j+1] > 0 and variables[abs(clauses[i][j+1])-1] == 1:
                cnt += 1
                kill = 1
                break
        if kill == 0:
            unsatisfied[uns] = i
            uns += 1
        kill = 0
    return uns
