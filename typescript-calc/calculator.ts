/*
// *** basic terms ***
TVM = time value of money
PV = present value of money
i = annual interest rate
n = number of payment periods per year
t = number of years
// *** compound terms ***
r = i / n
N = n * t
// *** functions ***
TVM = PV x ((1 + r)^N)
Discount Factor = (((1 + r)^N) -1) / (r(1 + r)^N)
Payments = Amount / Discount Factor
Payments = (principal * r) / (1 - (1 + r)^(-1 * N));
*/

// calculate time value of money
function tvm(
  principal: number,
  interestRate: number,
  periodsPerYear: number,
  numberOfYears: number
): number {
  let n = periodsPerYear * numberOfYears;
  let r = interestRate / periodsPerYear;
  return bankerRound(principal * Math.pow(1 + r, n), 2);
}

// banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number
// this function applies the rounding to the last digit requested with "decimalDigits", decimalDigits = 0 returns a rounded integer
function bankerRound(number: number, decimalDigits: number): number {
  // add the required zeros for the user plus one for doing the rounding against
  // add one extra zero to deal with JavaScript's poor float handling
  let addedZeros = Math.pow(10, decimalDigits + 2);
  // remove the extra zero we added to deal with JavaScript's float issues
  let trunc = Math.round(number * addedZeros * 0.1);
  switch (trunc % 10) {
    // numbers ending in 5 are handled differently
    case 5:
      // the last digit is known to be 5
      // so %2 is 0.5 for even integers, 1.5 for odd integers
      if ((trunc * 0.1) % 2 > 1) {
        // something like 1.5 will always round UP to 2
        trunc = Math.floor(trunc * 0.1) + 1;
      } else {
        // while 2.5 would round DOWN to 2
        trunc = Math.floor(trunc * 0.1);
      }
      break;
    default:
      //normal up/down rounding for all other numbers
      trunc = Math.round(trunc * 0.1);
  }
  //send the number back with the correct number of decimal digits
  return trunc / (addedZeros * 0.01);
}

// calculate the balance across the life of a loan
// returns an object array with some data for each payment period
function calcBalance(
  balance: number,
  payment: number,
  interestRate: number,
  periodsPerYear: number,
  paymentNumber: number,
  accInterest: number,
  payTable: object[]
): object[] {
  if (bankerRound(balance, 2) > 0) {
    // amortize the interest to calculate the payment's interest
    let paymentInterest = (interestRate / periodsPerYear) * balance;
    accInterest = accInterest + paymentInterest;
    // calculate the balance after this payment
    let endBalance = balance - (payment - paymentInterest);
    payTable.push({
      paymentNumber: paymentNumber,
      startBalance: bankerRound(balance, 2),
      endBalance: Math.abs(bankerRound(endBalance, 2)),
      paymentPrincipal: bankerRound(payment - paymentInterest, 2),
      paymentInterest: bankerRound(paymentInterest, 2),
      accumulatedInterest: bankerRound(accInterest, 2),
      amountPaidToDate: bankerRound(payment * paymentNumber, 2),
    });
    calcBalance(
      endBalance,
      payment,
      interestRate,
      periodsPerYear,
      paymentNumber + 1,
      accInterest,
      payTable
    );
  }
  return payTable;
}

function loanCalc(
  principal: number,
  interestRate: number,
  periodsPerYear: number,
  numberOfYears: number
): object {
  // calculate the periodic payment
  let n: number = periodsPerYear * numberOfYears;
  let r: number = interestRate / periodsPerYear;
  let payment: number = (principal * r) / (1 - Math.pow(1 + r, -1 * n));

  // round the payment to induce a small amount of error (reduces full overpayment on final payment)
  payment = bankerRound(payment, 8);
  let loanTotal: number = payment * periodsPerYear * numberOfYears;
  let paymentTable: object = calcBalance(
    principal,
    payment,
    interestRate,
    periodsPerYear,
    1,
    0,
    []
  );

  return {
    "periodic payment": +payment.toFixed(2),
    principal: +principal.toFixed(2),
    "total paid": +loanTotal.toFixed(2),
    "interest paid": +(loanTotal - principal).toFixed(2),
    "payment table": paymentTable,
  };
}

// make it work with node
try {
  if (process.argv !== undefined) {
    var args = process.argv.slice(2);
    if (args.length !== 4) {
      // console.log(tvm(27200, 0.036, 12, 1));
      console.log(loanCalc(27200, 0.036, 12, 5));
    } else {
      try {
        args.map((elm: number, ind: number) => {
          let num: number = Number.parseFloat(elm);
          if (isNaN(num)) {
            throw `Argument ${
              ind + 1
            }, "${elm}" can't be converted to a number.`;
          } else {
            args[ind] = num;
          }
        });
        // console.log(args);
        console.log(loanCalc(args[0], args[1], args[2], args[3]));
      } catch (e) {
        console.log(e);
      }
    }
  }
} catch {}