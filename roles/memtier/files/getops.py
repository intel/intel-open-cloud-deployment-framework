import os
import sys

if __name__ == '__main__':
    directory = sys.argv[1]
    num_pods = int(sys.argv[2])
    sets = [0]*num_pods
    gets = [0]*num_pods
    sets_percent = [0]*num_pods
    gets_percent = [0]*num_pods
    ops_sum = []
    for file in os.listdir(directory):
        filename_list = file.split('-')
        pod_no = filename_list[-1]
        if '.' in pod_no:
            pod_no = pod_no.split('.')[0]
        pod_no = int(pod_no)

        with open(os.path.join(directory, file)) as f:
            get_ops = True
            check_SET = False
            check_GET = False
            prev_get = 0
            prev_set = 0
            for line in f.readlines():
                if get_ops:
                    if 'Sets' in line:
                        sets[pod_no] = (float(line.split()[1]))
                        continue
                    elif 'Gets' in line:
                        gets[pod_no] = (float(line.split()[1]))
                        get_ops = False
                        check_SET = True
                        continue
                if check_SET:
                    if 'SET' in line:
                        msec = float(line.split()[1])
                        if msec < 1.0:
                            prev_set = float(line.split()[-1])
                            continue
                        elif msec >= 1.0:
                            if msec > 1.0:
                                print("SET 1.0 does not exist at pod "+str(pod_no)+" use the previous <1.0 % "+str(prev_get))
                                sets_percent[pod_no] = prev_set
                            else:
                                sets_percent[pod_no] = float(line.split()[-1])
                            check_SET = False
                            check_GET = True
                if check_GET:
                    if 'GET' in line:
                        msec = float(line.split()[1])
                        if msec < 1.0:
                            prev_get = float(line.split()[-1])
                            continue
                        elif msec >= 1.0:
                            if msec > 1.0:
                                print("GET 1.0 does not exist at pod "+str(pod_no)+" use the previous <1.0 % "+str(prev_get))
                                gets_percent[pod_no] = prev_get
                            else:
                                gets_percent[pod_no] = float(line.split()[-1])
                            break
    ops = 0
    for i in range(num_pods):
        ops += (gets[i] * gets_percent[i] + sets[i] * sets_percent[i])/100
    ops_sum.append(ops)
    #print(sets, gets, sets_percent, gets_percent, ops)
    print("for files in "+directory)
    print(sum(ops_sum))

