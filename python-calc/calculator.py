import sys
import math
import json

#  *** basic terms ***
# TVM = time value of money
# PV = present value of money
# i = annual interest rate
# n = number of payment periods per year
# t = number of years
#  *** compound terms ***
# r = i / n
# N = n * t
#  *** functions ***
# TVM = PV x ((1 + r)^N)
# Discount Factor = (((1 + r)^N) -1) / (r(1 + r)^N)
# Payments = Amount / Discount Factor
# Payments = (principal * r) / (1 - (1 + r)^(-1 * N))


# calculate time value of money
def tvm (principal, interestRate, periodsPerYear, numberOfYears):
    n = periodsPerYear * numberOfYears
    r = interestRate / periodsPerYear
    print(round(principal * ((1 + r)**n), 2))
    return round(principal * ((1 + r)**n), 2)

# banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number
# banker's rounding function isn't needed in Python3 because that's how it rounds by default

# calculate the balance across the life of a loan
# returns an object array with some data for each payment period
def calc_balance (balance,payment,interestRate,periodsPerYear,
        paymentNumber,accInterest,payTable):
    
    if math.floor(balance) > 0.0:
        # amortize the interest to calculate the payment's interest
        paymentInterest = (interestRate / periodsPerYear) * balance
        accInterest = accInterest + paymentInterest
        # calculate the balance after this payment
        endBalance = balance - (payment - paymentInterest)
        payTable.append(dict(
            paymentNumber = paymentNumber,
            startBalance = round(balance, 2),
            endBalance = abs(round(endBalance, 2)),
            paymentPrincipal = round(payment - paymentInterest, 2),
            paymentInterest = round(paymentInterest, 2),
            accumulatedInterest = round(accInterest, 2),
            amountPaidToDate = round(payment * paymentNumber, 2),
        ))
        calc_balance(endBalance, payment, interestRate, periodsPerYear,
          (paymentNumber + 1), accInterest, payTable)

    # if math.floor(balance) <= 0:
    #   print("returning")
    return payTable

def loan_calc (principal,interestRate,periodsPerYear,numberOfYears):
    # calculate the periodic payment
    n = periodsPerYear * numberOfYears
    r = interestRate / periodsPerYear
    payment = (principal * r) / (1 - (1 + r)**(-1 * n))

    # round the payment to induce a small amount of error (reduces full overpayment on final payment)
    payment = round(payment, 8)

    loanTotal = payment * periodsPerYear * numberOfYears
    #paymentTable = []
    paymentTable = calc_balance( principal, payment, interestRate, periodsPerYear, 1, 0, [] )

    #print(calc_balance( principal, payment, interestRate, periodsPerYear, 1, 0, [] ))
    loanDetails = dict(
        periodicPayment = round(payment, 2),
        principal = round(principal, 2),
        totalPaid = round(loanTotal, 2),
        interestPaid = round((loanTotal - principal), 2),
        paymentTable = paymentTable
    )
    print(json.dumps(loanDetails))


def dummy():
  # tvm(10_000.0, 0.1, 12.0, 1.0)
  loan_calc(27_200, .036, 56, 17)


def main():
  if len(sys.argv[1:]) < 4:
    dummy()
  else:
    args = []
    for i in sys.argv[1:]:
      i = float(i)
      args.append(i)

    # print("args: ", args)
    # tvm(args[0],args[1],args[2],args[3])
    loan_calc(args[0],args[1],args[2],args[3])
    
main()
