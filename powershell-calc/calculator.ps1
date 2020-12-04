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
# Payments = (principal * r) / (1 - (1 + r)^(-1 * N));

param(
    [decimal] $principal,
    [float] $interestRate,
    [int32] $periodsPerYear,
    [int32] $numberOfYears
)

# calculate time value of money
function tvm {
    [outputtype([float])]
    param(
        [decimal] $principal,
        [float] $interestRate,
        [int32] $periodsPerYear,
        [int32] $numberOfYears
    )
    [decimal] $n = $periodsPerYear * $numberOfYears;
    [decimal] $r = $interestRate / $periodsPerYear;
    [Math]::Round($principal * [Math]::pow(1 + $r, $n), 2);
}

# banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number
# banker's rounding function isn't needed in PowerShell because that's how it rounds by default

# calculate the balance across the life of a loan
# returns an object array with some data for each payment period
function calcBalance {
    param (
        [decimal] $balance,
        [decimal] $payment,
        [float] $interestRate,
        [int32] $periodsPerYear,
        [int32] $paymentNumber,
        [decimal] $accInterest,
        [array] $payTable
    )
    if ([Math]::floor($balance) -gt 0) {
        # amortize the interest to calculate the payment's interest
        [decimal] $paymentInterest = ($interestRate / $periodsPerYear) * $balance;
        [decimal] $accInterest = $accInterest + $paymentInterest;
        # calculate the balance after this payment
        [decimal] $endBalance = $balance - ($payment - $paymentInterest);
        $payTable += [PSCustomObject] @{
            paymentNumber       = $paymentNumber
            startBalance        = [Math]::Round($balance, 2)
            endBalance          = [Math]::Abs([Math]::Round($endBalance, 2))
            paymentPrincipal    = [Math]::Round($payment - $paymentInterest, 2)
            paymentInterest     = [Math]::Round($paymentInterest, 2)
            accumulatedInterest = [Math]::Round($accInterest, 2)
            amountPaidToDate    = [Math]::Round($payment * $paymentNumber, 2)
        };
        calcBalance $endBalance $payment $interestRate $periodsPerYear $($paymentNumber + 1) $accInterest $payTable; 
    }
    if ([Math]::floor($balance) -le 0) { return $payTable };
}

function loanCalc {
    param(
        [decimal] $principal,
        [float] $interestRate,
        [int32] $periodsPerYear,
        [int32] $numberOfYears
    )
    # calculate the periodic payment
    [decimal] $n = $periodsPerYear * $numberOfYears;
    [decimal] $r = $interestRate / $periodsPerYear;
    [decimal] $payment = ($principal * $r) / (1 - [Math]::pow(1 + $r, -1 * $n));

    # round the payment to induce a small amount of error (reduces full overpayment on final payment)
    $payment = [Math]::Round($payment, 8);

    [decimal] $loanTotal = $payment * $periodsPerYear * $numberOfYears;
    #var paymentTable = "";
    [object] $paymentTable = calcBalance $principal $payment $interestRate $periodsPerYear 1 0 @();

    [PSCustomObject]@{
        "periodic payment" = [Math]::Round($payment, 2)
        "principal"        = [Math]::Round($principal, 2)
        "total paid"       = [Math]::Round($loanTotal, 2)
        "interest paid"    = [Math]::Round(($loanTotal - $principal), 2)
        "payment table"    = $paymentTable
    }
}

function dummy {
    tvm 10000.0 0.1 12 1
    loanCalc 27200.0 0.036 365 8
}

if ( [Environment]::GetCommandLineArgs().length -eq 5) {
    try {
        [decimal]  [Environment]::GetCommandLineArgs()[1] 
        loanCalc $principal $interestRate $periodsPerYear $numberOfYears
    }
    catch {
        dummy
    }
}
else {
    loanCalc $principal $interestRate $periodsPerYear $numberOfYears | ConvertTo-Json -Compress
}
