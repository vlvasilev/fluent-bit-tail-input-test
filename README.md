# What this test is testing

This test is testing the fluent-bit tail plugin under hight load.

# How it works.

There is a fluent-bit deployed in Kubernetes environment as DaemonSet.
A tail input plugin is set which watch files in /var/log/containers.
After that a logger application is deployed as Deployment which spawns 
100 pods each of which logs 5000 messages numbered from 0 to 4999.
A file output plugin stores the logs under `/logs` directory for each file. 
In the end of the test we wait for 15 minutes to receive all of the 
500000 logs.

# The result from the test

Each test result is stored under `test-<test number>` directory.
In this directory are created directories for each fluent-bit pod instance, e.g. `test-1/fluent-bit-av64d`.
If there are file in the output plugin which does not contain all of the 5000 logs a copy of this file
is stored in this directory. All of the output files are stored under `test-<test number>/<fluent-bit_pod_name>/file_out-<fluent-bit_pod_name>`

# How to use this test.
./test.sh /path/to/the/kubeconfig

# Prerequisites

 - `kubectl` to apply the fluent-bit and the logger applications.
 - `kubernetes` cluster