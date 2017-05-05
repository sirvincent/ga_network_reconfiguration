Genetic Algorithm Network Reconfiguration
=====================

Genetic algorithm for reducing the power loss in an electrical network consisting out of 119 nodes.
Based on the paper:
Zhang, Dong, Zhengcai Fu, and Liuchun Zhang. "An improved TS algorithm for loss-minimum reconfiguration in large-scale distribution systems." Electric Power Systems Research 77.5 (2007): 685-694.

The network has binary encoded 2^132 search options, sequence encoded 1.44*10^18 search options. Consequently the search space is much to large to brute-force the optimal network configuration within a reasonable time span. 
Therefore we reconfigure the network by using a genetic algorithm and see if we can achieve the lowest power loss in the network within a reasonable time frame. The result is compared with a simple Monte Carlo algorithm.

The genetic algorithm is based on two functions that use the matlab matpower package: http://www.pserc.cornell.edu/matpower/ We assume the package directory is situated in the working directory. we used version 4.1. Both the functions, valid_119.m & calculation_119.m are from Kaifeng Yang. 

Main result
-----------

![Result](https://raw.githubusercontent.com/sirvincent/ga_network_reconfiguration/master/performance.png)
The genetic algorithm found the lowest power loss achievable in the electrical network; 869.7272 kW within 70 seconds.

Future Work
-----------
A report will be uploaded explaining in detail the found results and the genetic algorithm implemented.


Special Thanks To 
------------
Kaifang Yang for the functions and Prof. Dr. T. Bäck for giving the course Evolutionary Algorithm at Leiden University.
The genetic algorithm and monte carlo algorithm were part of an assignment for the Evolutionary Algorithms course.
