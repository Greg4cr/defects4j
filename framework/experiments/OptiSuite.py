# Gregory Gay (greg@greggay.com)
# OptiSuite
# A simple genetic algorithm that can generate subsuites of a master test suite
# optimized for size, coverage level, or both.

# Command line options:
# -m <filename of input matrix>
#        Format of matrix is:
#            name of test class, trial ID, name of test case, coverage element 1, ... , coverage element N
#        For example:
#            LocaleUtils_ESTest.java, 9, test01(), 1, 0, 1, 1
# -n <number of suites to generate>
# -c <coverage target>
#        Options are a number (0-100), "min", "max", and "ignore".
# -s <size target>
#        Options are a number (0-100), "min", "max", and "ignore".
# -p <population size>
#        Default is 100.
# -b <search budget>
#        Number of generations to optimize. Default is 100
# -r <percent of population to retain>
#        Input should be an float [0-1]. Default is 10% (0.10)
# -t <percent of population to mutate>
#        Input should be a float [0-1]. Default is 20% (0.20)
# -x <percent of population to create through crossover>
#        Input should be a float [0-1]. Default is 20% (0.20)
# -a <crossover operator>
#        Options are "OP" (one-point), "UC" (uniform crossover), "DR" (discrete recombination)
#        Default is "DR"
# -q <threshold for score stagnation>
#        Quit optimization if the best score has remained stagnant for too long
#        Default is 5 generations
# -o <filename of output CSV>
#        Default = "suites.csv"
# -z <seed for random number generator>
#        Default is the system time
# -D
#        Print debugging text. Default is off.

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import getopt
import sys
import os
from math import *
from numpy import *
from random import *
from copy import *

class OptiSuite(): 

    matrix = []
    suites = []
    covTarget = 100
    sizeTarget = 1
    populationSize = 100
    population = []
    budget = 100
    percentRetain = 0.1
    percentMutate = 0.2
    percentCrossover = 0.2
    crossoverOperator = "DR"
    stagnantThreshold = 5
    debug = 0

    # Produce and optimize test suites
    # numSuites = number of suites to produce
    def optimizeSuites(self, numSuites):
       
        print "Repeat, Generations to Convergence, Best Fitness Score, Suite Size of Best Suite, Coverage of Best Suite, Cov Goal, Size Goal, Population Size, Budget, Percent Retain, Percent Mutate, Percent Crossover, Crossover Operator, Stagnation Threshold"
        # For each suite to optimize
        for repeat in range(0,numSuites):
            self.population = []
            if self.debug == 1:
                print "---- Repeat:",repeat

            # Keep track of best score to date.
            bestScore = 100.0
            best = []
            stagnation = 0
            convergenceGen = 0

            # Generate initial population
            for member in range(0,self.populationSize):
                # Each initial member is a randomly generated suite of size 1...max
                self.population.append([self.generateRandomSuite(randint(1,len(self.matrix))), 0.0])
        
            # Optimize and produce new population
            for generation in range(0,self.budget+1):
                # Score all members of the population
                for member in range(0,len(self.population)):
                    suite=deepcopy(self.population[member][0])
                    self.population[member] = [suite, self.calculateSOFitness(suite)]

                # Sort and identify best members
                self.population = deepcopy(sorted(self.population,key=lambda a_entry: a_entry[1]))
                
                if self.population[0][1] < bestScore:
                    bestScore = deepcopy(self.population[0][1])
                    best = deepcopy(self.population[0][0])
                    convergenceGen=generation
                    stagnation = 0

                else: 
                    stagnation+=1
                    
                if self.debug == 1:
                    print "---- Generation:",generation,", Best Score:",bestScore
                    
                    popScores = []
                    for entry in range(0,len(self.population)):
                        popScores.append(self.population[entry][1])
                    print "---- Population Fitness:",popScores

                # If an optimal solution is found, or the population has stagnated, quit    
                if bestScore == 0.0 or stagnation == self.stagnantThreshold:
                    break
                else:
                    # Form new population

                    # Grab top X% for new population
                    newPopulation = deepcopy(self.population[0:int(self.percentRetain*self.populationSize)])
                    topSolutions = deepcopy(self.population[0:int(self.percentRetain*self.populationSize)])

                    # Create M mutations for new population
                    for toAdd in range(0, int(self.percentMutate * self.populationSize)):
                        size = len(newPopulation)
                        newPopulation.append([self.mutateSuite(topSolutions[randint(0,len(topSolutions)-1)][0]), 0.0])

                    # Perform crossover N times
                    for toAdd in range(0, int((self.percentCrossover * self.populationSize) / 2)):
                        size = len(newPopulation)
                        children = self.createChildren(topSolutions[randint(0, len(topSolutions) - 1)][0], topSolutions[randint(0, len(topSolutions) - 1)][0])
                        newPopulation.append([children[0], 0.0])
                        size = len(newPopulation)
                        newPopulation.append([children[1], 0.0])

                    # Add N random members to maintain diversity
                    for toAdd in range(len(newPopulation),self.populationSize):
                        newPopulation.append([self.generateRandomSuite(randint(1,len(self.matrix))), 0.0])

                    self.population = deepcopy(newPopulation)

            if bestScore == 0.0:
                self.suites.append(best)
            else:
                # Perform one last sort and append top member to output suite
                if self.population[0][1] < bestScore:
                    bestScore = deepcopy(self.population[0][1])
                    best = deepcopy(self.population[0][0])

                self.suites.append(best)
            #print "root(",pow(self.normalize(len(best),1,len(self.matrix)) - self.normalize(self.sizeTarget,1,len(self.matrix)),2),"+",pow(self.normalize(self.calculateCoverage(best),0,100) - self.normalize(self.covTarget,0,100),2),"=",sqrt(pow(self.normalize(len(best),1,len(self.matrix)) - self.normalize(self.sizeTarget,1,len(self.matrix)),2)+pow(self.normalize(self.calculateCoverage(best),0,100) - self.normalize(self.covTarget,0,100),2))

            print str(repeat)+","+str(convergenceGen)+","+str(bestScore)+","+str(len(best))+","+str(self.calculateCoverage(best))+","+str(self.sizeTarget)+","+str(self.covTarget)+","+str(self.populationSize)+","+str(self.budget)+","+str(self.percentRetain)+","+str(self.percentMutate)+","+str(self.percentCrossover)+","+self.crossoverOperator+","+str(self.stagnantThreshold)

            if self.debug == 1:
                popScores = []

                for entry in range(0,len(self.population)):
                    popScores.append(self.population[entry][1])

                print "---- Population Fitness: ",popScores

    # Turn on debug text printing
    def setDebug(self):
        if self.debug == 1:
            self.debug = 0
        else:
            self.debug = 1

    # Import matrix from CSV file. See header for CSV format.
    # filename = name and path of the file to import
    def importMatrix(self,filename):
        inFile = open(filename)
        
        for record in inFile:
            self.matrix.append(record.strip().split(","))

        inFile.close()

    # Set fitness goals
    # covTarget = coverage goal: "max", "min", "ignore", or a number.
    # sizeTarget = size goal: "max", "min", "ignore", or a number.
    # population = number of solutions considered at one time.
    # budget = number of rounds to optimize
    # pRetain = percent of population to retain
    # pMutate = percent of population to create through mutation
    # pCrossover = percent of population to create using the crossover operator
    # crossoverOperator = form of crossover to perform: "OP", "UC", "DR"
    # stagnant = threshold for score stagnation
    def setGoals(self, covTarget, sizeTarget, populationSize, budget, pRetain, pMutate, pCrossover, crossoverOperator, stagnantThreshold, rSeed):
        if covTarget == "min":
            self.covTarget = 0.000001
        elif covTarget == "max":
            self.covTarget = 100
        elif covTarget == "ignore":
            self.covTarget = -1
        else:
            self.covTarget = int(covTarget)

        if sizeTarget == "min":
            self.sizeTarget = 1
        elif sizeTarget == "max":
            self.sizeTarget = len(self.matrix)
        elif sizeTarget == "ignore":
            self.sizeTarget = -1
        else:
            self.sizeTarget = int(sizeTarget)

        self.populationSize = populationSize
        self.budget = budget
        if pRetain <= 1.0:
            self.percentRetain = pRetain
        else:
            self.percentRetain = (pRetain/100.0)

        if pMutate <= 1.0:
            self.percentMutate = pMutate
        else:
            self.percentMutate = (pMutate/100.0)

        if pRetain <= 1.0:
            self.percentCrossover = pCrossover
        else:
            self.percentCrossover = (pCrossover/100.0)

        self.stagnantThreshold = stagnantThreshold

        if crossoverOperator == "OP" or crossoverOperator == "DR" or crossoverOperator == "UC":
            self.crossoverOperator = crossoverOperator
        else:
            raise Exception("Unsupported crossover operator:",crossoverOperator)
 
        if rSeed != -1.0:
            seed(rSeed)

    # Calculate fitness as a single combination of objectives
    # suite = suite to calculate fitness for
    # returns fitness score for that suite
    def calculateSOFitness(self,suite):
        # Get size
        size = len(suite)
        # Get coverage
        coverage = self.calculateCoverage(suite)

        # Fitness is Euclidean distance between suite and targeted 
        # size and coverage, unless a target is ignored.
        fitness = 1
        if self.covTarget == -1 and self.sizeTarget != -1:
            fitness = sqrt(pow(self.normalize(size,1,len(self.matrix)) - self.normalize(self.sizeTarget,1,len(self.matrix)),2))
        elif self.sizeTarget==-1 and self.covTarget != -1:
            fitness = sqrt(pow(self.normalize(coverage,0,100) - self.normalize(self.covTarget,0,100),2))
        elif self.sizeTarget == -1 and self.covTarget == -1:
            # If ignoring both size and coverage level, just label this as optimal and return the random suite.
            fitness = 0
        else: 
            fitness = sqrt(pow(self.normalize(size,1,len(self.matrix)) - self.normalize(self.sizeTarget,1,len(self.matrix)),2) + pow(self.normalize(coverage,0,100) - self.normalize(self.covTarget,0,100),2))

        return fitness

    # Calculate fitness as multiple objectives
    # TODO: Support not yet implemented
    # suite = suite to calculate fitness for
    # returns (size score, coverage score)
    def calculateMOFitness(self,suite):
        # Get size
        size = len(suite)
        # Get coverage
        coverage = self.calculateCoverage(suite)

        # Fitness is minimization of the proportions of size and coverage 
        # to their targets, unless a target is ignored.
             
        if self.covTarget == -1:
            covScore = 0
        else:
            covScore = sqrt(pow(self.normalize(coverage,0,100) - self.normalize(self.covTarget,0,100),2))
     
        if self.sizeTarget == -1:
            sizeScore = 0
        else:
            sizeScore = sqrt(pow(self.normalize(size,1,len(self.matrix)) - self.normalize(self.sizeTarget,1,len(self.matrix)),2))

        return [sizeScore,covScore]

    # Normalize a value between 0 to 1, given a known max and min
    def normalize(self,number,minVal,maxVal):
        return (float(number - minVal)/float(maxVal - minVal))
       
    # Calculates coverage of a suite
    # suite = suite to calculate coverage of
    def calculateCoverage(self,suite):
        goals = len(suite[0])-3
        covered = zeros(goals)

        for test in suite:
            for entry in range(3,len(test)):
                goal = entry-3
                if test[entry] == "1":
                    covered[goal] = 1

        totalCovered=0 
        for goal in covered:
            if goal==1:
                totalCovered+=1

        return (float(totalCovered)/float(goals))*100;

    # Generate a random suite of a pre-specified size.
    # size = number of tests in the suite
    def generateRandomSuite(self, size):
        suite = []
        for entry in range(0,size):
            suite.append(deepcopy(self.matrix[randint(0,len(self.matrix)-1)]))

        return suite

    # Mutate a test suite
    # Possible mutations include adding, deleting, or replacing a test
    # suite = suite to mutate
    def mutateSuite(self, suite):
        # Choose a mutation
        choice = randint(1,3)

        # Do not delete the last test in the suite.
        if len(suite)==1 and choice==3:
            choice = randint(1,2)

        # Add a test
        if choice == 1:
            suite.append(deepcopy(self.matrix[randint(0,len(self.matrix)-1)]))
        elif choice == 2:
            # Replace a test
            suite[randint(0,len(suite)-1)] = deepcopy(self.matrix[randint(0,len(self.matrix)-1)])            
        else:
            # Delete a test
            del suite[randint(0,len(suite)-1)]

        return suite

    # Create children through crossover
    # parent1 = first parent suite
    # parent2 = second parent suite
    def createChildren(self, parent1, parent2):
        child1 = []
        child2 = []

        #if self.debug == 1:
        #    p1Tests=[]
        #    for entry in range(0,len(parent1)):
        #        p1Tests.append(parent1[entry][2])
        #    p2Tests=[]
        #    for entry in range(0,len(parent2)):
        #        p2Tests.append(parent2[entry][2])

         #   print "--- parent1,",p1Tests
         #   print "--- parent2,",p2Tests

        # One-Point crossover
        # Choose a single split point. First child inherits genes 0 - (split -1) 
        # from parent 1, and genes split - end from parent 2. Second
        # child inherits genes 0 - (split - 1) from parent 2 and genes split 
        # - end from parent 2.
        if self.crossoverOperator == "OP":
            split = randint(0,min(len(parent1) - 1, len(parent2) -1))
            
            for entry in range(0,split):
                child1.append(parent1[entry])
                child2.append(parent2[entry])

            for entry in range(split,max(len(parent1), len(parent2))):
                if entry < len(parent2):
                    child1.append(parent2[entry])
                if entry < len(parent1):
                    child2.append(parent1[entry])
        # Uniform Crossover
        # For each index, flip a coin. If 1, child1 gets the gene from parent1,
        # otherwise, child1 gets the gene from parent2. Child2 gets the other.
        elif self.crossoverOperator == "UC":
            for entry in range(0,max(len(parent1), len(parent2))):
                split = randint(1,2)
                if split == 1:
                    if entry < len(parent1):
                        child1.append(parent1[entry])
                    if entry < len(parent2):
                        child2.append(parent2[entry])
                else:
                    if entry < len(parent2):
                        child1.append(parent2[entry])
                    if entry < len(parent1):
                        child2.append(parent1[entry])
        # Discrete recombination
        # For each index and each child, flip a coin. If 1, gene from parent1,
        # if 2, gene from parent2.
        else:
            for entry in range(0,max(len(parent1),len(parent2))):
                split = randint(1,2)
                if split == 1:
                    if entry < len(parent1):
                       child1.append(parent1[entry])
                else:
                    if entry < len(parent2):
                       child1.append(parent2[entry])

                split = randint(1,2)
                if split == 1:
                    if entry < len(parent1):
                       child2.append(parent1[entry])
                else:
                    if entry < len(parent2):
                       child2.append(parent2[entry])

        #if self.debug == 1:
        #    c1Tests=[]
        #    for entry in range(0,len(child1)):
        #        c1Tests.append(child1[entry][2])
        #    c2Tests=[]
        #    for entry in range(0,len(child2)):
        #        c2Tests.append(child2[entry][2])

        #    print "----child1,",c1Tests
        #    print "----child2,",c2Tests

        return [child1, child2]

    # Write results to a CSV file
    # outputFile = name and path of the file to write the suites to
    def writeToCsv(self,outputFile):
        where = open(outputFile, 'w')
        where.write("Suite, Class, Trial, Test Name\n")       

        for line in range(len(self.suites)):
            for test in self.suites[line]:  
                where.write(str(line)+","+test[0]+","+test[1]+","+test[2]+"\n")

        where.close()

def main(argv):
    optimizer = OptiSuite()
    inFile = ""
    outFile = "suites.csv"
    suites = 1
    covTarget = "100"
    sizeTarget = "1"
    population = 100
    budget = 100
    pRetain = 0.1
    pMutate = 0.2
    pCrossover = 0.2
    stagnant = 5
    xoOp = "DR"
    rSeed = -1.0

    try:
        opts, args = getopt.getopt(argv,"hm:n:c:s:o:p:b:r:q:t:x:a:z:D")
    except getopt.GetoptError:
        print 'OptiSuite.py -m <input matrix> -n <number of suites to produce> -c <target coverage: #, min, max, ignore> -s <target suite size: #, min, max, ignore> -p <population size> -b <search budget> -r <percent of population to retain each round> -t <percent of population to create through mutation> -x <percent of population to create through crossover> -a <crossover operator> -q <stagnation threshold> -o <output filename> -z <rng seed> -D (turn on debug text)'
      	sys.exit(2)
  		
    for opt, arg in opts:
        if opt == "-h":
            print 'OptiSuite.py -m <input matrix> -n <number of suites to produce> -c <target coverage: #, min, max, ignore> -s <target suite size: #, min, max, ignore> -p <population size> -b <search budget> -r <percent of population to retain each round> -t <percent of population to create through mutation> -x <percent of population to create through crossover> -q <stagnation threshold> -a <crossover operator> -o <output filename> -z <rng seed> -D (turn on debug text)'
            sys.exit()
      	elif opt == "-m":
            inFile = arg
        elif opt == "-n":
            suites = int(arg)
        elif opt == "-o":
            outFile = arg
        elif opt == "-c":
            covTarget = arg
        elif opt == "-s":
            sizeTarget = arg
        elif opt == "-p":
            population = int(arg)
        elif opt == "-b":
            budget = int(arg)
        elif opt == "-r":
            pRetain = float(arg)
        elif opt == "-t":
            pMutate = float(arg)
        elif opt == "-x":
            pCrossover = float(arg)
        elif opt == "-q":
            stagnant = int(arg)
        elif opt == "-a":
            xoOp = arg
        elif opt == "-D":
            optimizer.setDebug()
        elif opt == "-z":
            rSeed = float(arg)

    if inFile == '':
        raise Exception('No input matrix specified')
    else:
        # Read in input matrix
        optimizer.importMatrix(inFile)

        # Configure optimization parameters
        optimizer.setGoals(covTarget, sizeTarget, population, budget, pRetain, pMutate, pCrossover, xoOp, stagnant, rSeed)

        # Generate suites
        optimizer.optimizeSuites(suites)

        # Write suites to CSV
        optimizer.writeToCsv(outFile)

# Call into main
if __name__ == '__main__':
    main(sys.argv[1:])
