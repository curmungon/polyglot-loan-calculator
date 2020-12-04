use std::env;

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

#[derive(Clone, Debug)]
struct PaymentData {
  payment_number: i32,
  start_balance: f64,
  end_balance: f64,
  payment_principal: f64,
  payment_interest: f64,
  accumulated_interest: f64,
  amount_paid_to_date: f64,
}

#[derive(Debug)]
struct LoanDetails {
  periodic_payment: f64,
  principal: f64,
  total_paid: f64,
  interest_paid: f64,
  payment_table: Vec<PaymentData>,
}

fn dummy() {
  // tvm(10_000.0, 0.1, 12.0, 1.0);
  loan_calc(27_200.0, 0.036, 365.0, 8.0)
}

fn main() {
  if env::args().len() < 3 {
    dummy();
  } else {
    let args: Vec<String> = env::args().collect();
    // tvm(
    //   args[1].parse::<f64>().unwrap(),
    //   args[2].parse::<f64>().unwrap(),
    //   args[3].parse::<f64>().unwrap(),
    //   args[4].parse::<f64>().unwrap(),
    // );
    loan_calc(
      args[1].parse::<f64>().unwrap(),
      args[2].parse::<f64>().unwrap(),
      args[3].parse::<f64>().unwrap(),
      args[4].parse::<f64>().unwrap(),
    );
  }
}

// calculate time value of money
pub fn tvm(principal: f64, interest_rate: f64, periods_per_year: f64, number_of_years: f64) -> f64 {
  let n: f64 = periods_per_year * number_of_years;
  let r: f64 = interest_rate / periods_per_year;
  println!(
    "tvm:{{ {} }}",
    banker_round(principal * (1.0 + r).powf(n), 2)
  );
  return banker_round(principal * (1.0 + r).powf(n), 2);
}

// banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number
// this function applies the rounding to the last digit requested with "decimal_digits", decimal_digits = 0 returns a rounded integer
pub fn banker_round(number: f64, decimal_digits: i32) -> f64 {
  // add the required zeros for the user plus one for doing the rounding against
  // add one extra zero to deal with float error
  let base: f64 = 10.0;
  let added_zeros: f64 = base.powi(decimal_digits + 2);
  //let added_zeros = Math.pow(10, decimal_digits + 2);
  // remove the extra zero we added to deal with float issues
  let mut trunc: f64 = (number * added_zeros * 0.1).trunc();
  match (trunc % 10.0) as i8 {
    // numbers ending in 5 are handled differently
    5 =>
    // the last digit is known to be 5
    // so %2 is 0.5 for even integers, 1.5 for odd integers
    {
      if (trunc * 0.1) % 2.0 > 1.0 {
        // something like 1.5 will always round UP to 2
        trunc = (trunc * 0.1).floor() + 1.0;
      } else {
        // while 2.5 would round DOWN to 2
        trunc = (trunc * 0.1).floor();
      }
    }
    _ =>
    //normal up/down rounding for all other numbers
    {
      trunc = (trunc * 0.1).round()
    }
  }
  //send the number back with the correct number of decimal digits
  return trunc / (added_zeros * 0.01);
}

// calculate the balance across the life of a loan
// returns an object array with some data for each payment period
fn calc_balance(
  balance: f64,
  payment: f64,
  interest_rate: f64,
  periods_per_year: f64,
  payment_number: i32,
  acc_interest: f64,
  pay_table: &mut Vec<PaymentData>,
) -> Vec<PaymentData> {
  if balance.floor() > 0.0 {
    // amortize the interest to calculate the payment's interest
    let payment_interest = (interest_rate / periods_per_year) * balance;
    let acc_interest = acc_interest + payment_interest;
    // calculate the balance after this payment
    let end_balance = balance - (payment - payment_interest);
    pay_table.push(PaymentData {
      payment_number,
      start_balance: banker_round(balance, 2),
      end_balance: (banker_round(end_balance, 2)).abs(),
      payment_principal: banker_round(payment - payment_interest, 2),
      payment_interest: banker_round(payment_interest, 2),
      accumulated_interest: banker_round(acc_interest, 2),
      amount_paid_to_date: banker_round(payment * payment_number as f64, 2),
    });
    // recursively calculate balance
    calc_balance(
      end_balance,
      payment,
      interest_rate,
      periods_per_year,
      payment_number + 1,
      acc_interest,
      pay_table,
    );
  }
  return pay_table.clone();
}

fn loan_calc(principal: f64, interest_rate: f64, periods_per_year: f64, number_of_years: f64) {
  // calculate the periodic payment
  let n: f64 = periods_per_year * number_of_years;
  let r: f64 = interest_rate / periods_per_year;
  let mut payment: f64 = (principal * r) / (1.0 - (1.0 + r).powf(-1.0 * n));

  // round the payment to induce a small amount of error (reduces full overpayment on final payment)
  payment = banker_round(payment, 8);
  let loan_total: f64 = payment * periods_per_year * number_of_years;
  let payment_table = calc_balance(
    principal,
    payment,
    interest_rate,
    periods_per_year,
    1,
    0.0,
    &mut Vec::with_capacity(n as usize + 1),
  );

  println!(
    "{:?}",
    LoanDetails {
      periodic_payment: banker_round(payment, 2),
      principal: banker_round(principal, 2),
      total_paid: banker_round(loan_total, 2),
      interest_paid: banker_round(loan_total - principal, 2),
      payment_table: payment_table,
    }
  );
}
