# Finds the required smoothing exponent to reach a certain supply for 1 year of 15 second blocks.

import math

def run(r,t,term,e):
    for i in range(1,360*24*60*60/15):
        term = term * (1 + r / (1 + i**e/t))
    return term

def main():
    r = 0.1
    t = 100.0
    target = 1000000
    terma = 42

    ea = 1.001
    eb = 2
    while terma < -1 or terma > 1:
        terma = run(r,t,1,ea) - target
        termb = run(r,t,1,eb) - target
        termm = run(r,t,1,(ea+eb)/2) - target 
        if termm > 0:
            ea = (ea+eb)/2
        else:
            eb = (ea+eb)/2

        print(ea,eb, terma+target)
    
    term = 1
    bn = 360*24*60*60/15
    be = math.floor(bn / 7)
    br = 0;

    for i in range(1,bn):
        term = term * (1 + r / (1 + i**ea/t))
        if i % be == 0:
            print((term - br)/be)
            br = term

    print(ea)


main()
