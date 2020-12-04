' *** basic terms ***
' TVM = time value of money
' PV = present value of money
' i = annual interest rate
' n = number of payment periods per year
' t = number of years
' *** compound terms ***
' r = i / n
' N = n * t
' *** Financial Functions ***
' TVM = PV x ((1 + r)^N)
' Discount Factor = (((1 + r)^N) -1) / (r(1 + r)^N)
' Payments = Amount / Discount Factor
' Payments = (principal * r) / (1 - (1 + r)^(-1 * N));

Function dummy() 
  ' WScript.echo tvm(10000.0, 0.1, 12.0, 1.0)
  WScript.echo loanCalc(27200.0, 0.036, 56, 13)
End Function

Select Case WSCript.Arguments.Count
    Case 4
        var1 = WSCript.Arguments(0)
        var2 = WSCript.Arguments(1)
        var3 = WSCript.Arguments(2)
        var4 = WSCript.Arguments(3)

        ' WScript.echo tvm(var1, var2, var3, var4)
        WScript.echo loanCalc(var1, var2, var3, var4)
    Case Else
        dummy
End Select


' calculate time value of money
Function tvm(principal, interestRate, periodsPerYear, numberOfYears)
    On Error Resume Next

    Dim n, r

    n = periodsPerYear * numberOfYears
    r = interestRate / periodsPerYear
    'tvm = bankerRound(principal * Math.pow(1 + r, n), 2);
    tvm = Round(principal * (1 + r)^n, 2)
End Function

' banker's rounding is the default in VBScript and not required to be implemented
' banker's rounding: <integer>.5 (i.e. 1.5, 14.5, etc) will be rounded up or down to the NEAREST EVEN number

' calculate the balance across the life of a loan
' returns an object array with some data for each payment period
Function calcBalance(balance,payment,interestRate,periodsPerYear, _ 
                     paymentNumber,accInterest,payTable)
  ' On Error Resume Next

    Dim paymentInterest, endBalance
  if Round(balance, 2) > 0 then
    ' amortize the interest to calculate the payment's interest
    paymentInterest = (interestRate / periodsPerYear) * balance
    accInterest = accInterest + paymentInterest
    ' calculate the balance after this payment
    endBalance = balance - (payment - paymentInterest)
    payTable = payTable + "{" + _ 
      """paymentNumber"": " + CStr(paymentNumber) + ", " + _ 
      """startBalance"": " + CStr(Round(balance, 2)) + ", " + _ 
      """endBalance"": " + CStr(Abs(Round(endBalance, 2))) + ", " + _ 
      """paymentPrincipal"": " + CStr(Round(payment - paymentInterest, 2)) + ", " + _ 
      """paymentInterest"": " + CStr(Round(paymentInterest, 2)) + ", " + _  
      """accumulatedInterest"": " + CStr(Round(accInterest, 2)) + ", " + _ 
      """amountPaidToDate"": " + CStr(Round(payment * paymentNumber, 2)) + _ 
    "}"
    if Abs(Round(endBalance, 2)) <> 0 then
        payTable = payTable + ","
    end if
    calcBalance endBalance,payment,interestRate,periodsPerYear, _ 
               (paymentNumber + 1),accInterest,payTable
  End If
  calcBalance = payTable
End Function

' truncate a number down by dropping extra digits
Function toFixed(decimalNum, digits)
    toFixed = CStr(Fix(decimalNum)) + Mid(CStr(CDbl(decimalNum - Fix(decimalNum) + 1 )),2, digits+1)
End Function

Function loanCalc(principal, interestRate, periodsPerYear, numberOfYears)
    'On Error Resume Next

    Dim n, r, payment, loanTotal, paymentTable

    ' calculate the periodic payment
    n = periodsPerYear * numberOfYears
    r = interestRate / periodsPerYear
    payment = (principal * r) / (1 - (1 + r)^(-1 * n))

    ' round the payment to induce a small amount of error (reduces full overpayment on final payment)
    payment = Round(payment, 8)
    loanTotal = payment * periodsPerYear * numberOfYears

    paymentTable = calcBalance(principal,payment,interestRate,periodsPerYear,1,0,"[") + "]"

    loanCalc = "{""periodic payment"": " + CStr(Round(payment,2)) + "," + vbCrLf + _ 
               """principal"": " + CStr(Round(principal, 2)) + "," + vbCrLf + _ 
               """total paid"": " + CStr(Round(loanTotal, 2)) + "," + vbCrLf + _ 
               """interest paid"": " + CStr(Round(loanTotal - principal, 2)) + "," + vbCrLf + _ 
               """payment table"": " + paymentTable + "}"

End Function
