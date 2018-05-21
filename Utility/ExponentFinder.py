# Finds the required smoothing exponent to reach a certain supply for 1 year of 15 second blocks.

def run(r,t,term,e):
    for i in range(1,360*24*60*60/15):
        term = term * (1 + r / (1 + i**e/t))
    return term

def main():
    r = 0.1
    t = 10000.0
    terma = 666
    target = 21000000
    
    ea = 1.1
    eb = 2.0
    while terma < -1 or terma > 1:
        terma = run(r,t,1,ea) - target
        termb = run(r,t,1,eb) - target
        termm = run(r,t,1,(ea+eb)/2) - target
        if termm > 0:
            ea = (ea+eb)/2
        else:
            eb = (ea+eb)/2
    
    term = 1
    for i in range(1,360*24*60*60/15):
        term = term * (1 + r / (1 + i**ea/t))
        if i % 100 == 0:
            print(term)

main()
